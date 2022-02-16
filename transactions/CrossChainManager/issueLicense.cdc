import CrossChainManager from "../../contracts/CrossChainManager.cdc"
import LockProxy from "../../contracts/LockProxy.cdc"

transaction(
    receiverAccountStr: String,
    receiverName: String,
    receiverPath: Path
) {
    prepare(acct: AuthAccount) {
        // edit below if you don't use default value
        // --------- edit below ---------
        var CAPath: PrivatePath = /private/PolyCA
        // --------- edit above ---------

        // don't edit below
        var receiverAccount: UInt64 = strToUint64(receiverAccountStr)
        var receiverPublicPath: PublicPath = (receiverPath as? PublicPath)!
        var CARef = acct.getCapability<&CrossChainManager.CertificationAuthority>(CAPath).borrow() ?? panic("Could not borrow a reference to the CA")
        assert(
            getAccount(LockProxy.uint64ToAddress(receiverAccount)).getCapability<&LockProxy.Locker{LockProxy.Portal, CrossChainManager.LicenseStore, CrossChainManager.MessageReceiver}>(receiverPublicPath).check(), 
            message: "Locker Reference was not created correctly")

        CARef.issueLicense(receiverAccount: receiverAccount, receiverName: receiverName, receiverPath: receiverPublicPath)

        assert(CrossChainManager.checkLicense(licenseAccount: LockProxy.uint64ToAddress(receiverAccount), licensePath: receiverPublicPath), 
            message: "License was not issued correctly")
    }
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