import LockProxy from 0xb68073c0c84c26e2
import CrossChainManager from 0xb68073c0c84c26e2

transaction {  
    prepare(acct: AuthAccount) {

        var lockerStoragePath = /storage/LockProxyBasicLocker
        // name = "LockProxy"
        var lockerPublicPath = /public/polynetwork_4fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc3   


        let locker <- LockProxy.createEmptyLocker()
        acct.save<@LockProxy.Locker>(<-locker, to: lockerStoragePath)
        log("Empty locker stored, storagePath: ")
        log(lockerPublicPath)

        let lockerRef = 
        acct.link<&LockProxy.Locker{LockProxy.Portal, CrossChainManager.LicenseStore, CrossChainManager.MessageReceiver}>
            (lockerPublicPath , target: lockerStoragePath)
        log("Reference created, publicPath: ")
        log(lockerPublicPath)

        assert(
            acct.getCapability<&LockProxy.Locker{LockProxy.Portal, CrossChainManager.LicenseStore, CrossChainManager.MessageReceiver}>(lockerPublicPath).check(), 
            message: "Locker Reference was not created correctly")
    }
}
 