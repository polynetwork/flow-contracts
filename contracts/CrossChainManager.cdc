import ZeroCopySink from "./ZeroCopySink.cdc"
import ZeroCopySource from "./ZeroCopySource.cdc"
import CCUtils from "./CCUtils.cdc"

pub contract CrossChainManager {
    
    // interface for contracts that need to use CrossChainManager
    pub resource interface LicenseStore {

        pub var license: @License
        pub fun receiveLicense(license: @License) {
            pre {
                self.license.isEmpty(): "receiveLicense: already have a not empty license!"
            }
        }
    }
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
    pub resource CrossChainMessage {
        pub let msgId: [UInt8]
        pub let polyTxHash: [UInt8]
        pub let sourceTxHash: [UInt8]

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
    pub resource License {
        pub let authorizedName: String
        pub let authorizedAccount: Address
        pub let authorizedPath: PublicPath
        pub let authorizedId: [UInt8]

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
    }

    pub fun createEmptyLicense(): @License {
        let license <- create License(authorizedAccount: 0x00, authorizedName: "invalid")
        assert(license.isEmpty(), message: "createEmptyLicense: try to create a not empty license")
        return <-license
    }
    
    // CA issue licenses for crossChainMessage sender/receiver
    pub resource CertificationAuthority {
        
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
    pub var ConKeepersPkList: [[UInt8]]
    pub var FromChainTxExist: {UInt64: {String: Bool}}
    pub var EthToPolyTxHashMap: {UInt256: String}

    pub var TemporaryMsgIdStore: [UInt8]

    pub var PublicPathMap: {String: PublicPath}

    // event definition
    pub event InitGenesisKeepersEvent(_ keepers: [String])
    pub event CrossChainEvent(txId: String, fromResource: String, toChainId: UInt64, toContract: String, rawdata: String)
    pub event verifySigAndExecuteTxEvent(fromChainID: UInt64, toContract: String, crossChainTxHash: String, fromChainTxHash: String)

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
    }

    access(account) fun unpause() {
        self.paused = false
    }

    access(account) fun setChainId(_ chainId: UInt64) {
        self.chainId = chainId
    }

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

    pub fun crossChain(license: @License, toChainId: UInt64, toContract: [UInt8], method: [UInt8], txData: [UInt8]): @License {
        pre {
            self.paused == false: "crossChain: contract paused"
            !license.isEmpty(): "crossChain: pass in empty license!"
        }

        var paramTxHash = self.EthToPolyTxHashIndex.toBigEndianBytes()
        var rawParam: [UInt8] = ZeroCopySink.WriteVarBytes(paramTxHash)
        rawParam.appendAll(ZeroCopySink.WriteVarBytes(HashAlgorithm.SHA2_256.hash("FlowCrossChainManager".utf8.concat(paramTxHash))))
        rawParam.appendAll(ZeroCopySink.WriteVarBytes(license.authorizedId))
        rawParam.appendAll(ZeroCopySink.WriteUint64(toChainId))
        rawParam.appendAll(ZeroCopySink.WriteVarBytes(toContract))
        rawParam.appendAll(ZeroCopySink.WriteVarBytes(method))
        rawParam.appendAll(ZeroCopySink.WriteVarBytes(txData))
        // log(rawParam)
        self.EthToPolyTxHashMap[self.EthToPolyTxHashIndex] = String.encodeHex(HashAlgorithm.SHA2_256.hash(rawParam))
        self.EthToPolyTxHashIndex = self.EthToPolyTxHashIndex + 1

        emit CrossChainEvent(
            txId: String.encodeHex(paramTxHash), 
            fromResource: String.encodeHex(license.authorizedId), 
            toChainId: toChainId, 
            toContract: String.encodeHex(toContract), 
            rawdata: String.encodeHex(rawParam))
        return <-license
    }

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

    access(contract) fun _getAccountFromLicenseId(_ licenseId: [UInt8]): Address {
        let tmp = ZeroCopySource.NextUint64(buff: licenseId, offset: 0)
        return CCUtils.uint64ToAddress((tmp.res as? UInt64)!)
    }

    access(contract) fun _getPathFromLicenseId(_ licenseId: [UInt8]): PublicPath {
        var tmp = ZeroCopySource.NextUint64(buff: licenseId, offset: 0)
        tmp = ZeroCopySource.NextVarBytes(buff: licenseId, offset: tmp.offset)
        return CrossChainManager.hashToPublicPathOpt(String.encodeHex((tmp.res as? [UInt8])!))!
    }

    access(contract) fun setPublicPathMap(_path: PublicPath, pathStr: String) {
        CrossChainManager.PublicPathMap[pathStr] = _path
    }

    pub fun hashToPublicPathOpt(_ hash: String): PublicPath? {
        return CrossChainManager.PublicPathMap[CrossChainManager.hashToPathIndentifier(hash)]
    }

    pub fun hashToPathIndentifier(_ hash: String): String {
        return "polynetwork_".concat(hash)
    }

    pub fun nameToPathIndentifier(_ _name: String): String {
        return CrossChainManager.hashToPathIndentifier(CrossChainManager.nameToHash(_name))
    }

    pub fun nameToHash(_ _name: String): String {
        return String.encodeHex(HashAlgorithm.SHA2_256.hash(_name.utf8))
    }

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
 