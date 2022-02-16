import LockProxy from "../../contracts/LockProxy.cdc"

transaction(
    fromTokenType: String,
    toChainId: UInt64,
    toAssetHash: String
){  
    prepare(acct: AuthAccount) {
        // edit below if you don't use default value
        // --------- edit below ---------
        var lockerStoragePath = /storage/LockProxyBasicLocker
        // name = "LockProxy"
        var lockerPublicPath = /public/polynetwork_4fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc3   
        // --------- edit above ---------

        // don't edit below
        let lockerRef = acct.borrow<&{LockProxy.BindingManager, LockProxy.Portal}>(from: lockerStoragePath)
            ?? panic("Could not borrow a reference to the bindingManager")

        lockerRef.bindAssetHash(fromTokenType: fromTokenType, toChainId: toChainId, toAssetHash: toAssetHash.decodeHex())
        
        assert(
            String.encodeHex(lockerRef.getTargetAsset(fromTokenType: fromTokenType, toChainId: toChainId)) == toAssetHash, 
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
 