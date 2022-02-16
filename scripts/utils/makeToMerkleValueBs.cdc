import ZeroCopySink from 0xZEROCOPYSINK
pub fun main(
    polyTxHash: String,
    fromChainId: UInt64,
    flowTxHash: String,
    crossChainId: String,
    fromContract: String,
    toChainId: UInt64,
    toContract: String,
    method: String,
    args: String
): String {
    var msg: [UInt8] = []

    msg.appendAll(ZeroCopySink.WriteVarBytes(polyTxHash.decodeHex()))
    msg.appendAll(ZeroCopySink.WriteUint64(fromChainId))
    msg.appendAll(ZeroCopySink.WriteVarBytes(flowTxHash.decodeHex()))
    msg.appendAll(ZeroCopySink.WriteVarBytes(crossChainId.decodeHex()))
    msg.appendAll(ZeroCopySink.WriteVarBytes(fromContract.decodeHex()))
    msg.appendAll(ZeroCopySink.WriteUint64(toChainId))
    msg.appendAll(ZeroCopySink.WriteVarBytes(toContract.decodeHex()))
    msg.appendAll(ZeroCopySink.WriteVarBytes(method.decodeHex()))
    msg.appendAll(ZeroCopySink.WriteVarBytes(args.decodeHex()))

    return String.encodeHex(msg)
}

/* 
  dev signers:

    1. Private Key: a415c49fc3017b173c7bf0f3e7549731231d59e8f9cd0bd5c9d5901056f4858e
       Public Key:  fb5a9f9cee7037c63b794da14a380078bbf9a7c17774466264942d7c71890053e9426292c82e7992217b5074ec8428950a2ed727eb8699a88f47c6ab0f6e8c50
    
    2. Private Key: 94bea92434afa3374705c85c39ff96800d92b1570d47dc0e47f4cf5e2b0b2079
       Public Key:  6db1d7eb0f4faf9a35ebdd8c8e6df89cb636c269f7b049cc145c5855c9ccbafda53049f46aad51e3a9d9cc7a264b690a81b33992df185bef660444b3fd4cac00
    
    3. Private Key: 8fc57915d26b80a95fa03ebf88a16fbf3b219a9c21712360932d31b6f23a5013
       Public Key:  db558bece69a8adcee15f3511e2742227e32856e669418499ca26c93cf3095f430386b910d15c208cd79ad96656d566fc3f345e2565d1c9102e562adda08f1db
    
    4. Private Key: 499a5ffbd36051bb115d3f82b95a896fbbfe56fe99760dad0b76e89b95183b05
       Public Key:  4baa606bd0e466a8590dc2dc131f0a3299c28264da9fa2cc66fcef8ef2ac7c134565092e0a142f54a1a3be77dfd6f960fc4424c10f9d8a519232412b161d2966
    
    5. Private Key: 1337ff36aa599152215efcec3dc057105c5175dc45505fc213d7b4a27bc360d7
       Public Key:  0c4abce5e4e13db7f2072c779890b0866cbf60588c23bd8c0994f213231043638da93aabda67a22b5f6ec3dd8b536727f1b741d6097ddbfe6eb8330ceb830aa2

*/
