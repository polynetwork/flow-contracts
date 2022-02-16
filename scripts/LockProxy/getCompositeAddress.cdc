import ZeroCopySink from 0xZEROCOPYSINK

pub fun main(addrStr: String, pathStr: String): String {
    var addr: UInt64 = strToUint64(addrStr)
    var res: [UInt8] = ZeroCopySink.WriteUint64(addr)
    res.appendAll(ZeroCopySink.WriteVarBytes(pathStr.utf8))
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