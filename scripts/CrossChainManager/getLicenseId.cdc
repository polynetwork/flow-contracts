import ZeroCopySink from 0xZEROCOPYSINK
import CrossChainManager from 0xCROSSCHAINMANAGER

pub fun main(addr: String, name: String): String {

    var res: [UInt8] = ZeroCopySink.WriteUint64(strToUint64(addr))
    res.appendAll(ZeroCopySink.WriteVarBytes(CrossChainManager.nameToHash(name).decodeHex()))
    return String.encodeHex(res)
}

pub fun strToUint64(_ str: String): UInt64 {
    var b: [UInt8] = str.decodeHex()
    var len = b.length
    var res: UInt64 = 0
    var index: Int = 0
    while (index<len) {
        res = res + UInt64(b[index]) * (0x1 << UInt64((len-index-1)*8))
        index = index + 1
    }
    return res
}