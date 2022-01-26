import CrossChainManager from 0xb68073c0c84c26e2
import LockProxy from 0xb68073c0c84c26e2

transaction {
    prepare(acct: AuthAccount) {

        var receiverAccount: UInt64 = 0xb68073c0c84c26e2
        var receiverName: String = "LockProxy"
        var receiverPath: PublicPath = /public/polynetwork_4fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc3

        var CAPath: PrivatePath = /private/PolyCA

        var CARef = acct.getCapability<&CrossChainManager.CertificationAuthority>(CAPath).borrow() ?? panic("Could not borrow a reference to the CA")
        assert(
            getAccount(LockProxy.uint64ToAddress(receiverAccount)).getCapability<&LockProxy.Locker{LockProxy.Portal, CrossChainManager.LicenseStore, CrossChainManager.MessageReceiver}>(receiverPath).check(), 
            message: "Locker Reference was not created correctly")

        CARef.issueLicense(receiverAccount: receiverAccount, receiverName: receiverName, receiverPath: receiverPath)

        assert(CrossChainManager.checkLicense(licenseAccount: LockProxy.uint64ToAddress(receiverAccount), licensePath: receiverPath), 
            message: "License was not issued correctly")
    }
}
 