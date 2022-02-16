import LockProxy from "../../contracts/LockProxy.cdc"
import CrossChainManager from "../../contracts/CrossChainManager.cdc"

transaction(
    userReceiverPublicPath: PublicPath,
    pathStr: String,
    sigs: [String],
    signers: [String],
    toMerkleValueBs: String
) {
    prepare(acct: AuthAccount) {

        let p = LockProxy.pathStrMap[String.encodeHex(pathStr.utf8)]
        if (p == nil) {
            LockProxy.registerReceiverPath(pathStr: pathStr, path: userReceiverPublicPath)
        }
        assert(LockProxy.pathStrMap[String.encodeHex(pathStr.utf8)]!.toString() == userReceiverPublicPath.toString(), 
            message: "fail to regesiter receiver path")

        assert(CrossChainManager.verifySigAndExecuteTx(
            sigs: strArrayToBytesArray(sigs), 
            signers: strArrayToBytesArray(signers), 
            toMerkleValueBs: toMerkleValueBs.decodeHex()
        ), message: "fail to verifySigAndExecuteTx")
    }
}

pub fun strArrayToBytesArray(_ strs: [String]): [[UInt8]] {
    let res: [[UInt8]] = []
    for str in strs {
        res.append(str.decodeHex())
    }
    return res
}