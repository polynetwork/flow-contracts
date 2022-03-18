import ZeroCopySink from "./ZeroCopySink.cdc"
import ZeroCopySource from "./ZeroCopySource.cdc"
import CCUtils from "./CCUtils.cdc"

pub contract CrossChainManager {
    
    // interface for contracts that need to use CrossChainManager
    // LicenseStore is used to receive and store license issued by CrossChainManager
    pub resource interface LicenseStore {

        pub var license: @License
        pub fun receiveLicense(license: @License) {
            pre {
                self.license.isEmpty(): "receiveLicense: already have a not empty license!"
            }
        }
    }
    // interface for contracts that need to use CrossChainManager
    // MessageReceiver is used to receive (and execute) CrossChain message from CrossChainManager
    pub resource interface MessageReceiver {

        pub fun receiveCrossChainMessage(
            crossChainMessageData: CrossChainMessageData,
            crossChainMessage: @CrossChainMessage?
        ): Bool {
            pre {
                CrossChainManager.checkCrossChainMessage(<-crossChainMessage!, crossChainMessageData: crossChainMessageData) 
                    : "receiveCrossChainMessage: invalid crossChainMessage"
            }
        }

    }
    
    // cross chain message struct
    /*  
        method: which method should be triggered
        args: call parameters
        fromContractAddr: identify which contract the message came from
        fromChainId: identify which chain the message came from
     */
    pub struct CrossChainMessageData {
        pub let method: [UInt8]
        pub let args: [UInt8]
        pub let fromContractAddr: [UInt8]
        pub let fromChainId: UInt64

        init(method: [UInt8], args: [UInt8], fromContractAddr: [UInt8], fromChainId: UInt64) {
            self.method = method
            self.args = args
            self.fromContractAddr = fromContractAddr
            self.fromChainId = fromChainId
        }
    }

    // cross chain message resource
    // @CrossChainMessage can only be generate by CrossChainManager, and will be destroyed immediately upon received
    // so @CrossChainMessage can be used to make sure the cross chain message comes from CrossChainManager
    /*
        msgId: identifer of the crossChain message
        polyTxHash: ToMerkleValue.txHash
        sourceTxHash: ToMerkleValue.makeTxParam.txHash
     */
    pub resource CrossChainMessage {
        access(contract) let msgId: [UInt8]
        access(contract) let polyTxHash: [UInt8]
        access(contract) let sourceTxHash: [UInt8]

        init(polyTxHash: [UInt8], sourceTxHash: [UInt8], method: [UInt8], args: [UInt8], fromContractAddr: [UInt8], fromChainId: UInt64) {
            var data = polyTxHash
            data.appendAll(sourceTxHash)
            data.appendAll(method)
            data.appendAll(args)
            data.appendAll(fromContractAddr)
            data.appendAll(fromChainId.toBigEndianBytes())
            self.sourceTxHash = sourceTxHash
            self.polyTxHash = polyTxHash
            self.msgId = HashAlgorithm.SHA2_256.hash(data)
        }
    }
    
    // crossChainMessage receiver need to query CrossChainManager to check if cross chain message is valid
    // return true if its valid
    // return false if its invalid
    // will destroy @CrossChainMessage whether it valid or not
    pub fun checkCrossChainMessage(_ crossChainMessage: @CrossChainMessage, crossChainMessageData: CrossChainMessageData): Bool {
        if self.TemporaryMsgIdStore.length == 0 || !CCUtils.equalBytes(x: crossChainMessage.msgId, y: self.TemporaryMsgIdStore) {
            destroy crossChainMessage
            return false
        }
        var data = crossChainMessage.polyTxHash
        data.appendAll(crossChainMessage.sourceTxHash)
        data.appendAll(crossChainMessageData.method)
        data.appendAll(crossChainMessageData.args)
        data.appendAll(crossChainMessageData.fromContractAddr)
        data.appendAll(crossChainMessageData.fromChainId.toBigEndianBytes())
        if !CCUtils.equalBytes(x: HashAlgorithm.SHA2_256.hash(data), y: crossChainMessage.msgId) {
            destroy crossChainMessage
            return false
        }
        destroy crossChainMessage
        self.TemporaryMsgIdStore = []
        return true
    }
    
    // crossChainMessage sender/receiver need to have a designated license
    /*
        authorizedName: name of the license owner
        authorizedAccount: account of the license owner
        authorizedPath: PublicPath of the license owner
        isEmpty(): return true if the license is empty (which means its an invalid license)
        getAuthorizedId(): returns authorizedId(used to identify the license) 
     */
    pub resource License {
        pub let authorizedName: String
        pub let authorizedAccount: Address
        pub let authorizedPath: PublicPath
        access(self) let authorizedId: [UInt8]

        init(authorizedAccount: UInt64, authorizedName: String) {

            var pathHash: [UInt8] = CrossChainManager.nameToHash(authorizedName).decodeHex()
            var accountBytes: [UInt8] = ZeroCopySink.WriteUint64(authorizedAccount)
            var pathHashBytes: [UInt8] = ZeroCopySink.WriteVarBytes(pathHash)

            self.authorizedId = accountBytes.concat(pathHashBytes)
            self.authorizedPath = CrossChainManager.hashToPublicPathOpt(String.encodeHex(pathHash))!
            self.authorizedName = authorizedName
            self.authorizedAccount = CCUtils.uint64ToAddress(authorizedAccount)
        }

        pub fun isEmpty(): Bool {
            if self.authorizedAccount == CCUtils.uint64ToAddress(0x00) && self.authorizedName == "invalid" {
                return true
            }
            return false
        }

        pub fun getAuthorizedId(): [UInt8] {
            return self.authorizedId
        }
    }

    // returns an empty license(@License.isEmpty() == true)
    pub fun createEmptyLicense(): @License {
        let license <- create License(authorizedAccount: 0x00, authorizedName: "invalid")
        assert(license.isEmpty(), message: "createEmptyLicense: try to create a not empty license")
        return <-license
    }
    
    // CA issue licenses for crossChainMessage sender/receiver
    pub resource CertificationAuthority {
        
        // issue license, receiver must implement @LicenseStore interface
        pub fun issueLicense(receiverAccount: UInt64, receiverName: String, receiverPath: PublicPath) {
            pre {
                CrossChainManager.getPublicPathStr(receiverPath) == CrossChainManager.nameToPathIndentifier(receiverName)
                : "issueLicense: receiverName and receiverPath do not match"
            }
            post {
                CrossChainManager.checkLicense(licenseAccount: CCUtils.uint64ToAddress(receiverAccount), licensePath: receiverPath)
                : "issueLicense: lincense was not set correctly"
            }
            var pathStr: String = CrossChainManager.nameToPathIndentifier(receiverName)
            CrossChainManager.setPublicPathMap(_path: receiverPath, pathStr: pathStr)

            let licenseReceiver = getAccount(CCUtils.uint64ToAddress(receiverAccount)).getCapability<&{LicenseStore}>(receiverPath).borrow() 
                ?? panic("issueLicense: fail to borrow receiver's LiceseStore")
                
            licenseReceiver.receiveLicense(license: <-create License(authorizedAccount: receiverAccount, authorizedName: receiverName))
        }
    }
    
    // check if there is a valid license in given account path
    // return true only if there is a non_empty @License in given PublicPath of given account
    // return false if there is no license or there is an empty @License
    pub fun checkLicense(licenseAccount: Address, licensePath: PublicPath): Bool {
        let licenseStoreOpt = getAccount(licenseAccount).getCapability<&{LicenseStore}>(licensePath).borrow()
        if licenseStoreOpt == nil {
            return false
        }
        let licenseStore = licenseStoreOpt!

        return !licenseStore.license.isEmpty()
    }

    // data store
    pub var paused: Bool
    pub var chainId: UInt64
    pub var EthToPolyTxHashIndex: UInt256
    access(contract) var ConKeepersPkList: [[UInt8]]
    access(contract) var FromChainTxExist: {UInt64: {String: Bool}}
    access(contract) var EthToPolyTxHashMap: {UInt256: String}

    access(contract) var TemporaryMsgIdStore: [UInt8]

    access(contract) var PublicPathMap: {String: PublicPath}

    // event definition
    pub event InitGenesisKeepersEvent(_ keepers: [String])
    pub event CrossChainEvent(txId: String, fromResource: String, toChainId: UInt64, toContract: String, rawdata: String)
    pub event verifySigAndExecuteTxEvent(fromChainID: UInt64, toContract: String, crossChainTxHash: String, fromChainTxHash: String)
    pub event PauseEvent()
    pub event UnpauseEvent()

    // admin can init/pause/unpaue the CrossChianManager and set ChainId 
    pub resource Admin {
        pub fun pause() {
            CrossChainManager.pause()
        }
        pub fun unpause() {
            CrossChainManager.unpause()
        }
        pub fun setChainId(_ chainId: UInt64) {
            CrossChainManager.setChainId(chainId)
        }   
        pub fun initGenesisKeepers(_ pubKeyList: [[UInt8]]): Bool {
            return CrossChainManager.initGenesisKeepers(pubKeyList)
        }
    }

    access(account) fun pause() {
        self.paused = true
        emit PauseEvent()
    }

    access(account) fun unpause() {
        self.paused = false
        emit UnpauseEvent()
    }

    access(account) fun setChainId(_ chainId: UInt64) {
        self.chainId = chainId
    }

    // set the keepers' public key of poly chain
    access(account) fun initGenesisKeepers(_ pubKeyList: [[UInt8]]): Bool {
        pre {
            self.paused == false: "initGenesisBlock: contract paused"
        }
        self.ConKeepersPkList = pubKeyList

        var keepers: [String] = []
        for pk in pubKeyList {
            keepers.append(String.encodeHex(pk))
        }

        emit InitGenesisKeepersEvent(keepers)
        return true
    }
    
    // call crossChain() to send cross chain message
    /*
        licnese: must provide a non-empty license to send crossChain message, this function will return license
        toChainId: target chain id
        toContract: target contract
        method: target method
        txData: call parameters
     */
    pub fun crossChain(license: @License, toChainId: UInt64, toContract: [UInt8], method: [UInt8], txData: [UInt8]): @License {
        pre {
            self.paused == false: "crossChain: contract paused"
            !license.isEmpty(): "crossChain: pass in empty license!"
        }

        var paramTxHash = self.EthToPolyTxHashIndex.toBigEndianBytes()
        var rawParam: [UInt8] = ZeroCopySink.WriteVarBytes(paramTxHash)
        rawParam.appendAll(ZeroCopySink.WriteVarBytes(HashAlgorithm.SHA2_256.hash("FlowCrossChainManager".utf8.concat(paramTxHash))))
        rawParam.appendAll(ZeroCopySink.WriteVarBytes(license.getAuthorizedId()))
        rawParam.appendAll(ZeroCopySink.WriteUint64(toChainId))
        rawParam.appendAll(ZeroCopySink.WriteVarBytes(toContract))
        rawParam.appendAll(ZeroCopySink.WriteVarBytes(method))
        rawParam.appendAll(ZeroCopySink.WriteVarBytes(txData))
        // log(rawParam)
        self.EthToPolyTxHashMap[self.EthToPolyTxHashIndex] = String.encodeHex(HashAlgorithm.SHA2_256.hash(rawParam))
        self.EthToPolyTxHashIndex = self.EthToPolyTxHashIndex + 1

        emit CrossChainEvent(
            txId: String.encodeHex(paramTxHash), 
            fromResource: String.encodeHex(license.getAuthorizedId()), 
            toChainId: toChainId, 
            toContract: String.encodeHex(toContract), 
            rawdata: String.encodeHex(rawParam))
        return <-license
    }

    // relayer will relay crossChain message to target chain by call verifySigAndExecuteTx()
    // will revert if sigs is invalid , or this crossChain tx has already been executed
    /*
        sigs: signatures of toMerkleValueBs from poly chain keepers
        signers: same order as sigs
        toMerkleValue: serialized ToMerkleValue
     */
    pub fun verifySigAndExecuteTx(sigs: [[UInt8]], signers: [[UInt8]], toMerkleValueBs: [UInt8]): Bool {
        pre {
            self.paused == false: "verifySigAndExecuteTx: contract paused"
        }
        let keepers = self.ConKeepersPkList
        let n = UInt256(keepers.length)
        assert(CCUtils.verifySig(_rawData: toMerkleValueBs, _sigList: sigs, _signers: signers, _keepers: keepers, _m: n - ( n - 1) / 3),
            message: "verifySigAndExecuteTx: Verify signatures failed! ")
        
        // Parse the toMerkleValue struct and make sure the tx has not been processed, then mark this tx as processed
        let toMerkleValue = CCUtils.deserializeMerkleValue(toMerkleValueBs)
        assert(!self.checkIfFromChainTxExist(fromChainId: toMerkleValue.fromChainId, fromChainTx: toMerkleValue.txHash), 
            message: "verifySigAndExecuteTx: the transaction has been executed!")
        assert(self.markFromChainTxExist(fromChainId: toMerkleValue.fromChainId, fromChainTx: toMerkleValue.txHash), 
            message: "verifySigAndExecuteTx: Save crosschain tx exist failed!")

        // we need to check the transaction is for Flow network
        assert(toMerkleValue.makeTxParam.toChainId == self.chainId, 
            message: "verifySigAndExecuteTx: This Tx is not aiming at this network!")
        
        // dynamically invoke the targeting resource
        let crossChainMessage 
            <- create CrossChainMessage(
                polyTxHash: toMerkleValue.txHash, 
                sourceTxHash: toMerkleValue.makeTxParam.txHash, 
                method: toMerkleValue.makeTxParam.method, 
                args: toMerkleValue.makeTxParam.args, 
                fromContractAddr: toMerkleValue.makeTxParam.fromContract, 
                fromChainId: toMerkleValue.fromChainId)
        assert(
            self._executeCrossChainTx(
                crossChainMessage: <-crossChainMessage, 
                _toContract: toMerkleValue.makeTxParam.toContract, 
                _method: toMerkleValue.makeTxParam.method, 
                _args: toMerkleValue.makeTxParam.args, 
                _fromContractAddr: toMerkleValue.makeTxParam.fromContract, 
                _fromChainId: toMerkleValue.fromChainId),
            message: "verifySigAndExecuteTx: Execute CrossChain Tx failed!")

        emit verifySigAndExecuteTxEvent(
            fromChainID: toMerkleValue.fromChainId, 
            toContract: String.encodeHex(toMerkleValue.makeTxParam.toContract), 
            crossChainTxHash: String.encodeHex(toMerkleValue.txHash), 
            fromChainTxHash: String.encodeHex(toMerkleValue.makeTxParam.txHash))
        return true
    }

    access(contract) fun checkIfFromChainTxExist(fromChainId: UInt64, fromChainTx: [UInt8]): Bool {
        var txExist = self.FromChainTxExist[fromChainId] ?? {}
        return txExist[String.encodeHex(fromChainTx)] ?? false
    }

    access(contract) fun markFromChainTxExist(fromChainId: UInt64, fromChainTx: [UInt8]): Bool {
        var txExist = self.FromChainTxExist[fromChainId] ?? {}
        txExist[String.encodeHex(fromChainTx)] = true
        self.FromChainTxExist[fromChainId] = txExist
        return true
    }

    access(contract) fun _executeCrossChainTx(crossChainMessage: @CrossChainMessage, _toContract: [UInt8], _method: [UInt8], _args: [UInt8], _fromContractAddr: [UInt8], _fromChainId: UInt64): Bool {
        self.TemporaryMsgIdStore = crossChainMessage.msgId
        let receiver = getAccount(CrossChainManager._getAccountFromLicenseId(_toContract)).getCapability<&{MessageReceiver}>(CrossChainManager._getPathFromLicenseId(_toContract)).borrow()
            ?? panic("fail to borrow target MessageReceiver")
        var crossChainMessageData = CrossChainMessageData(method: _method, args: _args, fromContractAddr: _fromContractAddr, fromChainId: _fromChainId)
        assert(receiver.receiveCrossChainMessage(crossChainMessageData: crossChainMessageData, crossChainMessage: <-crossChainMessage),
            message: "CrossChainManager call business resource function failed")
        self.TemporaryMsgIdStore = []
        return true
    }
    
    // recover account from Licenseid
    access(contract) fun _getAccountFromLicenseId(_ licenseId: [UInt8]): Address {
        let tmp = ZeroCopySource.NextUint64(buff: licenseId, offset: 0)
        return CCUtils.uint64ToAddress((tmp.res as? UInt64)!)
    }

    // recover path from LicenseId
    access(contract) fun _getPathFromLicenseId(_ licenseId: [UInt8]): PublicPath {
        var tmp = ZeroCopySource.NextUint64(buff: licenseId, offset: 0)
        tmp = ZeroCopySource.NextVarBytes(buff: licenseId, offset: tmp.offset)
        return CrossChainManager.hashToPublicPathOpt(String.encodeHex((tmp.res as? [UInt8])!))!
    }

    // register a String->PublicPath map since cadence do not support PublicPath() yet
    access(contract) fun setPublicPathMap(_path: PublicPath, pathStr: String) {
        CrossChainManager.PublicPathMap[pathStr] = _path
    }

    // Hash -> PublicPath
    pub fun hashToPublicPathOpt(_ hash: String): PublicPath? {
        return CrossChainManager.PublicPathMap[CrossChainManager.hashToPathIndentifier(hash)]
    }

    // Hash -> PathIndentifier(which has a prefix)
    pub fun hashToPathIndentifier(_ hash: String): String {
        return "polynetwork_".concat(hash)
    }

    // Name -> PathIndentifier(which has a prefix)
    pub fun nameToPathIndentifier(_ _name: String): String {
        return CrossChainManager.hashToPathIndentifier(CrossChainManager.nameToHash(_name))
    }

    // Name -> Hash
    pub fun nameToHash(_ _name: String): String {
        return String.encodeHex(HashAlgorithm.SHA2_256.hash(_name.utf8))
    }

    // PublicPath -> String
    // e.g. /public/abc -> "abc"
    pub fun getPublicPathStr(_ _path: PublicPath): String {
        return _path.toString().slice(from: 8, upTo: _path.toString().length) 
    }

    init() {

        self.chainId = 999

        self.paused = false
        self.EthToPolyTxHashIndex = 0
        self.ConKeepersPkList = []
        self.FromChainTxExist = {}
        self.EthToPolyTxHashMap = {}

        self.TemporaryMsgIdStore = []

        self.PublicPathMap = {}

        self.account.save(<-create CertificationAuthority(), to: /storage/PolyCrossChainCA)
        self.account.link<&CertificationAuthority>(/private/PolyCA, target: /storage/PolyCrossChainCA)

        self.account.save(<-create Admin(), to: /storage/PolyCCMAdmin)
        self.account.link<&Admin>(/private/CCMAdmin, target: /storage/PolyCCMAdmin)

        
        // set up empty licnese path
        self.setPublicPathMap(_path: /public/polynetwork_f1234d75178d892a133a410355a5a990cf75d2f33eba25d575943d4df632f3a4, pathStr: "polynetwork_f1234d75178d892a133a410355a5a990cf75d2f33eba25d575943d4df632f3a4")
    }
}
 