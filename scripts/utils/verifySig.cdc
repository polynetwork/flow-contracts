import CCUtils from 0xCCUTILS

pub fun main(data: [UInt8], sig: [UInt8], signer: [UInt8]): Bool {
    return CCUtils.verifySig(_rawData: data, _sigList: [sig], _signers: [signer], _keepers: [signer], _m: 1)
}