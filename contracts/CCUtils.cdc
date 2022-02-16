import ZeroCopySink from "./ZeroCopySink.cdc"
import ZeroCopySource from "./ZeroCopySource.cdc"

pub contract CCUtils {

    pub struct ToMerkleValue {
        pub(set) var txHash: [UInt8]
        pub(set) var fromChainId: UInt64
        pub(set) var makeTxParam: TxParam
        init(txHash: [UInt8], fromChainId: UInt64, makeTxParam: TxParam) {
            self.txHash = txHash
            self.fromChainId = fromChainId
            self.makeTxParam = makeTxParam
        }
    }

    pub struct TxParam {
        pub(set) var txHash: [UInt8]
        pub(set) var crossChainId: [UInt8]
        pub(set) var fromContract: [UInt8]
        pub(set) var toChainId: UInt64
        pub(set) var toContract: [UInt8]
        pub(set) var method: [UInt8]
        pub(set) var args: [UInt8]
        init(txHash: [UInt8], crossChainId: [UInt8], fromContract: [UInt8], toChainId: UInt64, toContract: [UInt8], method: [UInt8], args: [UInt8]) {
            self.txHash = txHash
            self.crossChainId = crossChainId
            self.fromContract = fromContract
            self.toChainId = toChainId
            self.toContract = toContract
            self.method = method
            self.args = args
        }
    }

    pub let FLOW_PUBKEY_LEN: Int 
    pub let FLOW_SIGNATURE_LEN: Int 
    init() {
        self.FLOW_PUBKEY_LEN = 64
        self.FLOW_SIGNATURE_LEN = 64
    }


    pub fun verifySig(_rawData: [UInt8], _sigList: [[UInt8]], _signers: [[UInt8]], _keepers: [[UInt8]], _m: UInt256): Bool {
        
        var index = 0
        while true {
            if (index >= _sigList.length) {
                break
            }
            assert(_signers[index].length == self.FLOW_PUBKEY_LEN, message: "verifySig: invalid public key length")
            assert(_sigList[index].length == self.FLOW_SIGNATURE_LEN, message: "verifySig: invalid signatture length")
            var pk = PublicKey(publicKey: _signers[index], signatureAlgorithm: SignatureAlgorithm.ECDSA_secp256k1)
            if !pk.verify(
                signature: _sigList[index],
                signedData: _rawData,
                domainSeparationTag: "FLOW-V0.0-user",
                hashAlgorithm: HashAlgorithm.SHA2_256
            ) {
                return false
            }
            index = index + 1
        }

        return self.containMAddresses(_keepers: _keepers, _signers: _signers, _m: _m)
    }

    pub fun containMAddresses(_keepers: [[UInt8]], _signers: [[UInt8]], _m: UInt256): Bool {
        var cnt = 0 as UInt256
        for keeper in _keepers {
            for signer in _signers {
                if self.equalBytes(x: keeper, y: signer) {
                    cnt = cnt + 1
                    break
                }
            }
        }
        return cnt >= _m
    }

    pub fun deserializeMerkleValue(_ valueBs: [UInt8]): ToMerkleValue {
        var toMerkleValue: ToMerkleValue = ToMerkleValue(txHash: [], fromChainId: 0, makeTxParam: TxParam(txHash: [], crossChainId: [], fromContract: [], toChainId: 0, toContract: [], method: [], args: []))

        var tmp = ZeroCopySource.NextVarBytes(buff: valueBs, offset: 0)
        toMerkleValue.txHash = (tmp.res as? [UInt8])!

        tmp = ZeroCopySource.NextUint64(buff: valueBs, offset: tmp.offset)
        toMerkleValue.fromChainId = (tmp.res as? UInt64)!

        tmp = ZeroCopySource.NextVarBytes(buff: valueBs, offset: tmp.offset)
        toMerkleValue.makeTxParam.txHash = (tmp.res as? [UInt8])!

        tmp = ZeroCopySource.NextVarBytes(buff: valueBs, offset: tmp.offset)
        toMerkleValue.makeTxParam.crossChainId = (tmp.res as? [UInt8])!

        tmp = ZeroCopySource.NextVarBytes(buff: valueBs, offset: tmp.offset)
        toMerkleValue.makeTxParam.fromContract = (tmp.res as? [UInt8])!

        tmp = ZeroCopySource.NextUint64(buff: valueBs, offset: tmp.offset)
        toMerkleValue.makeTxParam.toChainId = (tmp.res as? UInt64)!

        tmp = ZeroCopySource.NextVarBytes(buff: valueBs, offset: tmp.offset)
        toMerkleValue.makeTxParam.toContract = (tmp.res as? [UInt8])!

        tmp = ZeroCopySource.NextVarBytes(buff: valueBs, offset: tmp.offset)
        toMerkleValue.makeTxParam.method = (tmp.res as? [UInt8])!

        tmp = ZeroCopySource.NextVarBytes(buff: valueBs, offset: tmp.offset)
        toMerkleValue.makeTxParam.args = (tmp.res as? [UInt8])!

        return toMerkleValue
    }

    pub fun equalBytes(x: [UInt8], y: [UInt8]): Bool {
        return String.encodeHex(x) == String.encodeHex(y)
    }

    pub fun uint64ToAddress(_ n: UInt64): Address {
        return Address(n)
    }
}
 