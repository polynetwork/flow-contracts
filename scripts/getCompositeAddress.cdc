import ExampleToken from 0xb68073c0c84c26e2
import ZeroCopySink from 0xb68073c0c84c26e2

pub fun main(): String {
    let addr: UInt64 = 0xb68073c0c84c26e2
    var pathStr: String = "exampleTokenReceiver"

    var res: [UInt8] = ZeroCopySink.WriteUint64(addr)
    res.appendAll(ZeroCopySink.WriteVarBytes(pathStr.utf8))
    return String.encodeHex(res)
}