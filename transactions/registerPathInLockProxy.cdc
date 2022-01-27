import LockProxy from 0xf8d6e0586b0a20c7

transaction {
    prepare(acct: AuthAccount) {

        // --------- edit below ---------
        var userVaultPublicPath = /public/exampleTokenReceiver
        var pathStr = "exampleTokenReceiver"
        // --------- edit above ---------

        // don't edit below
        LockProxy.registerReceiverPath(pathStr: pathStr, path: userVaultPublicPath)
        
        assert(LockProxy.pathStrMap[String.encodeHex(pathStr.utf8)]!.toString() == userVaultPublicPath.toString(), message: "fail while checkout")
    }
}
