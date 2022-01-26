import LockProxy from 0xb68073c0c84c26e2

transaction {  

    prepare(acct: AuthAccount) {

        var lockerStoragePath = /storage/LockProxyBasicLocker
        var lockerPublicPath = /public/polynetwork_4fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc3    
        var toChainId: UInt64 = 999
        var targetProxyHash: [UInt8] = "e2264cc8c07380b6204fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc3".decodeHex()

        let lockerRef = acct.borrow<&{LockProxy.BindingManager, LockProxy.Portal}>(from: lockerStoragePath)
            ?? panic("Could not borrow a reference to the bindingManager")

        lockerRef.bindProxyHash(toChainId: toChainId, targetProxyHash: targetProxyHash)
        
        assert(
            String.encodeHex(lockerRef.getTargetProxy(toChainId)) == String.encodeHex(targetProxyHash), 
            message: "check proxy binding information failed, invalid targetProxyHash")

        log("bindProxyHash success!")
        log("toChainId: ")
        log(toChainId)
        log("targetProxyHash: ")
        log(targetProxyHash)

    }
    
}