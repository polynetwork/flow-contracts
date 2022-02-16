import ZeroCopySink from 0xZEROCOPYSINK
import LockProxy from LOCKPROXY
pub fun main(
    toAssetHash: String,
    toAddress: String,
    amount: UFix64
): String {
    var msg: [UInt8] = []

    msg.appendAll(ZeroCopySink.WriteVarBytes(toAssetHash.decodeHex()))
    msg.appendAll(ZeroCopySink.WriteVarBytes(toAddress.decodeHex()))
    msg.appendAll(ZeroCopySink.WriteUint255((LockProxy.ufix64ToUint256(amount))))

    return String.encodeHex(msg)
}