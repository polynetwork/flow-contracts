import { ec as EC } from "elliptic";
const ec = new EC("secp256k1");
import { SHA256 } from "sha2";
// import { signWithKey } from "flow-js-testing";
import { 
    executeScriptWithErrorRaised,
    basicTransformer 
} from "./common";

const devSigners = [
    {
        privateKey: "a415c49fc3017b173c7bf0f3e7549731231d59e8f9cd0bd5c9d5901056f4858e",
        publicKey:  "5af6adb56c1395592201ef052d112b9aa312370119a10e45bc874e0c525b5781beb52dec36b49666438768e2d7141b3c26b075461c342d7fbc4ca128896d45f4"
    },
    {
        privateKey: "94bea92434afa3374705c85c39ff96800d92b1570d47dc0e47f4cf5e2b0b2079",
        publicKey:  "a473fa7b55bac592b26c4d32aaf3e0ebff141049d97e85e726ba4930b17c19ce156d6329601fd5659693e5a1f6ac6272071cd2368bde6026175d9cfa3b78514f"
    },
    {
        privateKey: "8fc57915d26b80a95fa03ebf88a16fbf3b219a9c21712360932d31b6f23a5013",
        publicKey:  "9006b36413f5dc335d50082f51f36282dd8073e9c30c898e4620ecc8cbcd8b15553191c92d256f56b99618ad25bed134cabed5a75267e3da347cc54dfe8f0217"
    },
    {
        privateKey: "499a5ffbd36051bb115d3f82b95a896fbbfe56fe99760dad0b76e89b95183b05",
        publicKey:  "f99ab8709700e3192f30ffbbee7a83cdbe18472fd941e7fcd09edda1e429b733e4031b201a4a8df3e4d2738130ffef83ae06103f62c233fc92fc41e57e1e85b1"
    },
    {
        privateKey: "1337ff36aa599152215efcec3dc057105c5175dc45505fc213d7b4a27bc360d7",
        publicKey:  "e8432e25b5855f87263b4a97f7e77d3a3f186552bc2f05812d358bd5020347e88e6134caba2c6f130308e6fffd7f6ffbdccec5b95c74cfda2e29111b22266899"
    }
]
const fakers = [
    {
        privateKey: "f136efa0152a49263c06aaaef9a2cacb07574495001e722515630c89a1d998ef",
        publicKey:  "ccb081570f5b0fd72dab1531526ddd7367ce8e64955010271978cfe98233048d5093225b8527c91251b9ae5428656b02791519c83881d24a910ea50616227bba"
    },
    {
        privateKey: "165732e43605aecd9f395ff0267949a289b301a020cc4c0154436ab1fb91a476",
        publicKey:  "b6f66c554e88d1b51a4833826427fa987759e59318a247f1dc0a1cb2969f098290697f9ec0b31a137e5496a3a4519bb75c63e03a1cf20d424b6da0be7823ccff"
    },
    {
        privateKey: "e5255d026492634634c9551df663b14dcc3bf2587315a4b90c6c719a1db5ff26",
        publicKey:  "589afd2fabb2dcc90a406e0101210ff00a6b51457c7e3391aaa4fd029959c9d1b4af5eb8788e84db976d7c8a9090787af19c638cd34d215e45952ca9bc2061cd"
    },
    {
        privateKey: "ad295875ed874c5eaeef80f1339dd6b0383cf5ff61be46873e31100361352795",
        publicKey:  "891ed661e7aefff37f7c33b46507b16e1ad1cb545dd95a395ef8ef4a2cf1ae8a6a7d821efc8c81f3c1d2ff01e211afa36c2d726e2a5704c320f4198227721af"
    },
    {
        privateKey: "416aa7ee0dae8e4945dbaea4f6a77a0f3c906ad029b0f0fbcd0f785442e82670",
        publicKey:  "a88f5cc40922a1b55735e16a4ae5b4728b4406ecf0b340dbba3c8d331d4d809a9bcd26640a1bd3620ff860af816faa9b82e094cb10bc1a0aa066377586d7e8b6"
    }
]
const minSigNum = 4

export const sign = async (privateKey, msgHex) => {
    return signWithKey(privateKey, msgHex);
}

export const getToMerkleValueBs = async (
    polyTxHash,
    fromChainId,
    flowTxHash,
    crossChainId,
    fromContract,
    toChainId,
    toContract,
    method,
    _args
) => {
	const name = "utils/makeToMerkleValueBs";
	const args = [
        polyTxHash,
        fromChainId,
        flowTxHash,
        crossChainId,
        fromContract,
        toChainId,
        toContract,
        method,
        _args
    ];
	const transformers = [basicTransformer];

    return executeScriptWithErrorRaised({ name, args, transformers })
}

export const getArgs = async (
    toAssetHash,
    toAddress,
    amount
) => {
	const name = "utils/makeCCMArgs";
	const args = [
        toAssetHash,
        toAddress,
        amount
    ];
	const transformers = [basicTransformer];

    return executeScriptWithErrorRaised({ name, args, transformers })
}

export const addTag = async (data) => {
    const tag = "464c4f572d56302e302d75736572000000000000000000000000000000000000" // bytes("FLOW-V0.0-user")

    return tag + data
}

export const getDevSignerPublicKeys = async () => {
    var res = []
    for (let i=0;i< devSigners.length;i++) {
        res.push(devSigners[i].publicKey)
    }
    return res
}

export const generateSignatures = async (msgHex) => {
    var sigs = []
    var signers = []
    for (let i=0;i< minSigNum;i++) {
        let sig = await sign(devSigners[i].privateKey, msgHex)
        sigs.push(sig)
        signers.push(devSigners[i].publicKey)
    }
    return [sigs, signers]
}

export const genrateFakeSignatures = async (msgHex) => {
    var sigs = []
    var signers = []
    for (let i=0;i< minSigNum;i++) {
        let sig = await sign(fakers[i].privateKey, msgHex)
        sigs.push(sig)
        signers.push(fakers[i].publicKey)
    }
    return [sigs, signers]
}

export const shallThrow = async (ix) => {
    try {
        await ix
    } catch {
        return
    }
    throw("ERROR! Should throw but it didn't");
}

export const hashMsgHex = (msgHex) => {
  return SHA256(msgHex, "hex").toString("hex");
};

export const signWithKey = (privateKey, msgHex) => {
    const key = ec.keyFromPrivate(Buffer.from(privateKey, "hex"));
    const sig = key.sign(hashMsgHex(msgHex));
    const n = 32; // half of signature length?
    const r = sig.r.toArrayLike(Buffer, "be", n);
    const s = sig.s.toArrayLike(Buffer, "be", n);
    return Buffer.concat([r, s]).toString("hex");
  };

export const getSECP256K1Pk = (flag) => {
    var keys = []
    if (flag == true) {
        for (let i=0;i< devSigners.length;i++) {
            var sk = devSigners[i].privateKey
            var key = ec.keyFromPrivate(Buffer.from(sk, "hex"));
            var pk = key.getPublic(true).x.toString(16) + key.getPublic(true).y.toString(16)
            keys.push({publicKey: pk, privateKey: sk})
        }
    } else {
        for (let i=0;i< fakers.length;i++) {
            var sk = fakers[i].privateKey
            var key = ec.keyFromPrivate(Buffer.from(sk, "hex"));
            var pk = key.getPublic(true).x.toString(16) + key.getPublic(true).y.toString(16)
            keys.push({publicKey: pk, privateKey: sk})
        }
    }
    return keys
}