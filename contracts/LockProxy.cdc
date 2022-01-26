import CrossChainManager from "./CrossChainManager.cdc"
import ZeroCopySink from "./ZeroCopySink.cdc"
import ZeroCopySource from "./ZeroCopySource.cdc"
import FungibleToken from "./flowFT/FungibleToken.cdc"

// import FungibleToken from 0xee82856bf20e2aa6 // on emulator
// import FungibleToken from 0x9a0766d93b6608b7 // on testnet
// import FungibleToken from 0xf233dcee88fe0abe // on mainnet

pub contract LockProxy {

    pub resource interface BindingManager {
        pub var proxyHashMap: {UInt64: [UInt8]}
        pub var assetHashMap: {String: {UInt64: [UInt8]}}

        pub fun bindProxyHash(toChainId: UInt64, targetProxyHash: [UInt8]): Bool  
        pub fun bindAssetHash(fromTokenType: String, toChainId: UInt64, toAssetHash: [UInt8]): Bool 
    }

    pub resource interface Portal {
        pub fun lock(fund: @FungibleToken.Vault, toChainId: UInt64 , toAddress: [UInt8]): Bool
        pub fun deposite(_ fund: @FungibleToken.Vault)
        pub fun getTargetAsset(fromTokenType: String, toChainId: UInt64): [UInt8]
        pub fun getTargetProxy(_ toChainId: UInt64): [UInt8]
    }

    pub resource Locker: BindingManager, Portal, CrossChainManager.LicenseStore, CrossChainManager.MessageReceiver {
        pub var drawers: @{String: FungibleToken.Vault}
        pub var license: @CrossChainManager.License
        pub var proxyHashMap: {UInt64: [UInt8]}
        pub var assetHashMap: {String: {UInt64: [UInt8]}}

        // called by CrossChainManager
        pub fun receiveLicense(license: @CrossChainManager.License) {
            var emptyLicense: @CrossChainManager.License <- self.license <- license
            destroy emptyLicense
        }

        // called by CrossChainManager
        pub fun receiveCrossChainMessage(
            crossChainMessageData: CrossChainManager.CrossChainMessageData,
            crossChainMessage: @CrossChainManager.CrossChainMessage?
        ): Bool {
            switch String.encodeHex(crossChainMessageData.method) {
                case String.encodeHex("unlock".utf8):
                    self.unlock(
                        argsBs: crossChainMessageData.args, 
                        fromContractAddr: crossChainMessageData.fromContractAddr, 
                        fromChainId: crossChainMessageData.fromChainId)
                default: 
                    panic("receiveCrossChainMessage: invalid method")
            }
            destroy crossChainMessage
            return true
        }

        pub fun bindProxyHash(toChainId: UInt64, targetProxyHash: [UInt8]): Bool {
            self.proxyHashMap[toChainId] = targetProxyHash
            return true
        }  

        pub fun bindAssetHash(fromTokenType: String, toChainId: UInt64, toAssetHash: [UInt8]): Bool {
            var tokenMap: {UInt64: [UInt8]} = self.assetHashMap[fromTokenType] ?? {}
            tokenMap[toChainId] = toAssetHash
            self.assetHashMap[fromTokenType] = tokenMap
            return true
        }

        pub fun getTargetAsset(fromTokenType: String, toChainId: UInt64): [UInt8] {
            var tokenMap: {UInt64: [UInt8]} = self.assetHashMap[fromTokenType] ?? {}
            return tokenMap[toChainId] ?? []
        }

        pub fun getTargetProxy(_ toChainId: UInt64): [UInt8] {
            return self.proxyHashMap[toChainId] ?? []
        }

        // cross chain entrance
        pub fun lock(fund: @FungibleToken.Vault, toChainId: UInt64 , toAddress: [UInt8]): Bool {
            var amount = UInt256(fund.balance)
            var fromTokenType = fund.getType().identifier
            var toAssetHash = self.getTargetAsset(fromTokenType: fromTokenType, toChainId: toChainId)
            assert(toAssetHash.length != 0, message: "lock: empty illegal toAssetHash")
            var toContract = self.getTargetProxy(toChainId)
            assert(toContract.length != 0, message: "lock: empty illegal toProxyHash")

            // transfer asset to lock_proxy contract
            self.deposite(<-fund)

            var txData: [UInt8] = []
            txData.appendAll(ZeroCopySink.WriteVarBytes(toAssetHash))
            txData.appendAll(ZeroCopySink.WriteVarBytes(toAddress))
            txData.appendAll(ZeroCopySink.WriteUint255(amount))
            
            var inputLicense <- CrossChainManager.createEmptyLicense()
            inputLicense <-> self.license
            var outputLicense <- CrossChainManager.crossChain(license: <-inputLicense, toChainId: toChainId, toContract: toContract, method: "unlock".utf8, txData: txData)
            outputLicense <-> self.license
            destroy outputLicense

            return true
        }

        pub fun deposite(_ fund: @FungibleToken.Vault) {
            var tokenType = String.encodeHex(fund.getType().identifier.utf8)
            var vaultOpt: @FungibleToken.Vault? <- nil
            vaultOpt <-> self.drawers[tokenType]
            if vaultOpt == nil {
                self.drawers[tokenType] <-! fund
                destroy vaultOpt
            } else {
                fund.deposit(from: <-vaultOpt!)
                self.drawers[tokenType] <-! fund
            }
        }

        access(self) fun unlock(argsBs: [UInt8], fromContractAddr: [UInt8], fromChainId: UInt64): Bool {
            
            var tmp = ZeroCopySource.NextVarBytes(buff: argsBs, offset: 0)
            var toAssetHash = (tmp.res as? [UInt8])!
            
            tmp = ZeroCopySource.NextVarBytes(buff: argsBs, offset: tmp.offset)
            var toAddress = (tmp.res as? [UInt8])!

            tmp = ZeroCopySource.NextUint255(buff: argsBs, offset: tmp.offset)
            var amount = (tmp.res as? UInt256)!
            
            assert(fromContractAddr.length != 0, 
                message: "unlock: from proxy contract address cannot be empty")
            assert(self.isValidFromProxy(fromContractAddr: fromContractAddr, fromChainId: fromChainId),
                message: "unlock: from Proxy contract address error!")
            assert(toAssetHash.length != 0,
                message: "unlock: toAssetHash cannot be empty")
            assert(toAddress.length != 0,
                message: "unlock: toAddress cannot be empty")

            var fund <- self.withdrawFromDrawer(amount: UFix64(amount), tokenType: String.encodeHex(toAssetHash))
            var toAccount = LockProxy._getAccountFromCompositeAddress(toAddress)
            var recipient = getAccount(toAccount)
            var receivePath = LockProxy._getPathFromCompositeAddress(toAddress)
            
            let receiverRef = recipient.getCapability(receivePath)
                      .borrow<&{FungibleToken.Receiver}>()
                      ?? panic("unlock: Could not borrow a reference to the receiver")
            
            receiverRef.deposit(from: <-fund)

            return true
        }


        access(self) fun withdrawFromDrawer(amount: UFix64, tokenType: String): @FungibleToken.Vault {
            var drawerOpt: @FungibleToken.Vault? <- nil
            drawerOpt <-> self.drawers[tokenType]
            var drawer <- drawerOpt!
            var res <- drawer.withdraw(amount: amount)
            self.drawers[tokenType] <-! drawer
            return <-res
        }

        access(self) fun isValidFromProxy(fromContractAddr: [UInt8], fromChainId: UInt64): Bool {
            var expectedProxy = self.getTargetProxy(fromChainId)
            return String.encodeHex(fromContractAddr) == String.encodeHex(expectedProxy)
        }

        init() {
            self.license <- CrossChainManager.createEmptyLicense()
            self.drawers <- {}
            self.proxyHashMap = {}
            self.assetHashMap = {}
        }

        destroy() {
            destroy self.drawers
            destroy self.license
        }
    }

    pub var pathStrMap: {String: PublicPath}

    init() {
        self.pathStrMap = {}
    }

    pub fun createEmptyLocker(): @Locker {
        return <- create Locker()
    }

    access(contract) fun _getAccountFromCompositeAddress(_ compositeAddress: [UInt8]): Address {
        let tmp = ZeroCopySource.NextUint64(buff: compositeAddress, offset: 0)
        return self.uint64ToAddress((tmp.res as? UInt64)!)
    }

    access(contract) fun _getPathFromCompositeAddress(_ compositeAddress: [UInt8]): PublicPath {
        var tmp = ZeroCopySource.NextUint64(buff: compositeAddress, offset: 0)
        tmp = ZeroCopySource.NextVarBytes(buff: compositeAddress, offset: tmp.offset)
        var pathBytes = (tmp.res as? [UInt8])!
        var pathBytesStr = String.encodeHex(pathBytes)
        return self.pathStrMap[pathBytesStr]!
    }

    pub fun registerReceiverPath(pathStr: String, path: PublicPath) {
        assert(pathStr == path.toString().slice(from: 8, upTo: path.toString().length), 
            message: "registerReceiverPath: path and pathStr do not match")
        self.pathStrMap[String.encodeHex(pathStr.utf8)] = path
    }

    pub fun uint64ToAddress(_ n: UInt64): Address {
        if (n >= 0x8000000000000000) {
            return Address(Int128(n)+0x10000000000000000)
        } else {
            return Address(Int128(n))
        }
    }

}
 