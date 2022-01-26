import CCUtils from 0xb68073c0c84c26e2

pub fun main(): Bool {
    var d = "abc".utf8
    var sig = "7304244cd70277db480152472f20a31faa2c322dff2a554b7dc860527877dde468f778e7c1ac546601bf75d61de0d3d25f9a88e6c1c592a196b43e307d81c5e9".decodeHex()
    var signer = "32e7b843d2af123275ac802e315bcd3da1fad066d744659cc1bdf31955ea7e671234fca1b522459cd9a256f92a7162d978e6ada509f3b59a04d87173dedf3bc2".decodeHex()
    return CCUtils.verifySig(_rawData: d, _sigList: [sig], _signers: [signer], _keepers: [signer], _m: 1)
}