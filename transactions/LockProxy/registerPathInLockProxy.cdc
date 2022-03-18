import LockProxy from "../../contracts/LockProxy.cdc"

transaction(
    userVaultPath: Path,
    pathStr: String
) {
    prepare(acct: AuthAccount) {

        let userVaultPublicPath = (userVaultPath as? PublicPath)!

        LockProxy.registerReceiverPath(pathStr: pathStr, path: userVaultPublicPath)
        
        assert(LockProxy.getPathFromStr(String.encodeHex(pathStr.utf8))!.toString() == userVaultPublicPath.toString(), message: "fail while checkout")
    }
}
