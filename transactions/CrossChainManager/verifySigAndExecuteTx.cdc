import CrossChainManager from "../../contracts/CrossChainManager.cdc"

transaction(
    sigs: [String],
    signers: [String],
    toMerkleValueBs: String
) {
    prepare(acct: AuthAccount) {

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