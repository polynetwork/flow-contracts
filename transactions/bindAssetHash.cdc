import LockProxy from 0xb68073c0c84c26e2

transaction {  

    prepare(acct: AuthAccount) {

        var lockerStoragePath = /storage/LockProxyBasicLocker
        var lockerPublicPath = /public/polynetwork_4fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc3   
        var fromTokenType: String = "A.b68073c0c84c26e2.ExampleToken.Vault"
        var toChainId: UInt64 = 999
        var toAssetHash: [UInt8] = "A.b68073c0c84c26e2.ExampleToken.Vault".utf8

        let lockerRef = acct.borrow<&{LockProxy.BindingManager, LockProxy.Portal}>(from: lockerStoragePath)
            ?? panic("Could not borrow a reference to the bindingManager")

        lockerRef.bindAssetHash(fromTokenType: fromTokenType, toChainId: toChainId, toAssetHash: toAssetHash)
        
        assert(
            String.encodeHex(lockerRef.getTargetAsset(fromTokenType: fromTokenType, toChainId: toChainId)) == String.encodeHex(toAssetHash), 
            message: "check asset binding information failed, invalid toAssetHash")

        log("bindAssetHash success!")
        log("fromTokenType: ")
        log(fromTokenType)
        log("toChainId: ")
        log(toChainId)
        log("toAssetHash: ")
        log(toAssetHash)

    }
    
}
 