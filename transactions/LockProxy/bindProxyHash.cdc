import LockProxy from "../../contracts/LockProxy.cdc"

transaction(
    toChainId: UInt64,
    targetProxyHash: String
) {  
    prepare(acct: AuthAccount) {
        // edit below if you don't use default value
        // --------- edit below ---------
        var lockerStoragePath = /storage/LockProxyBasicLocker
        // name = "LockProxy"
        var lockerPublicPath = /public/polynetwork_4fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc3   
        // --------- edit above ---------

        let lockerRef = acct.borrow<&{LockProxy.BindingManager, LockProxy.Portal}>(from: lockerStoragePath)
            ?? panic("Could not borrow a reference to the bindingManager")

        lockerRef.bindProxyHash(toChainId: toChainId, targetProxyHash: targetProxyHash.decodeHex())
        
        assert(
            String.encodeHex(lockerRef.getTargetProxy(toChainId)) == targetProxyHash, 
            message: "check proxy binding information failed, invalid targetProxyHash")

        log("bindProxyHash success!")
        log("toChainId: ")
        log(toChainId)
        log("targetProxyHash: ")
        log(targetProxyHash)

    }
    
}