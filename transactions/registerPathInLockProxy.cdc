import LockProxy from 0xf8d6e0586b0a20c7

transaction {
    prepare(acct: AuthAccount) {
        var userVaultPublicPath = /public/exampleTokenReceiver
        var pathStr = "exampleTokenReceiver"
        
        LockProxy.registerReceiverPath(pathStr: pathStr, path: userVaultPublicPath)
        
        assert(LockProxy.pathStrMap[String.encodeHex(pathStr.utf8)]!.toString() == userVaultPublicPath.toString(), message: "fail while checkout")
    }
}
