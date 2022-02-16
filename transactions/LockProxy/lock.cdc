import LockProxy from "../../contracts/LockProxy.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"

// import FungibleToken from 0xee82856bf20e2aa6 // on emulator
// import FungibleToken from 0x9a0766d93b6608b7 // on testnet
// import FungibleToken from 0xf233dcee88fe0abe // on mainnet

transaction(
    lockerAccount: Address,
    vaultPath: Path,
    toChainId: UInt64,
    toAddressStr: String,
    amount: UFix64
) {
    prepare(acct: AuthAccount) {
        
        // edit below if you don't use default value
        // --------- edit below ---------
        var lockerPublicPath = /public/polynetwork_4fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc3
        // --------- edit above ---------

        // don't edit below
        let toAddress: [UInt8] = toAddressStr.decodeHex()
        let vaultStoragePath: StoragePath = (vaultPath as? StoragePath)!
        let lockerRef = getAccount(lockerAccount).getCapability<&LockProxy.Locker{LockProxy.Portal}>(lockerPublicPath).borrow()
            ?? panic("fail to borrow Locker")

        let vaultRef = acct.borrow<&FungibleToken.Vault>(from: vaultStoragePath)
            ?? panic("Could not borrow a reference to the owner's vault")
        
        let fund <- vaultRef.withdraw(amount: amount)

        lockerRef.lock(fund: <-fund, toChainId: toChainId , toAddress: toAddress)
    }
}