pub fun main(
    data: String
): String {
    var msg: [UInt8] = "FLOW-V0.0-user".utf8
    msg.appendAll(data.decodeHex())
    return String.encodeHex(msg)
}