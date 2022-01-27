import LockProxy from 0xb68073c0c84c26e2
import FungibleToken from 0x9a0766d93b6608b7

// import FungibleToken from 0xee82856bf20e2aa6 // on emulator
// import FungibleToken from 0x9a0766d93b6608b7 // on testnet
// import FungibleToken from 0xf233dcee88fe0abe // on mainnet

transaction {
    prepare(acct: AuthAccount) {
        
        // --------- edit below ---------
        var lockerAccount: Address = 0xb68073c0c84c26e2
        var lockerPublicPath = /public/polynetwork_4fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc3
        var vaultStoragePath = /storage/exampleTokenVault
        var toChainId: UInt64 = 999
        var toAddress: [UInt8] = "e2264cc8c07380b6146578616d706c65546f6b656e5265636569766572".decodeHex()
        var amount: UFix64 = 8.0
        // --------- edit above ---------

        // don't edit below
        let lockerRef = getAccount(lockerAccount).getCapability<&LockProxy.Locker{LockProxy.Portal}>(lockerPublicPath).borrow()
            ?? panic("fail to borrow Locker")

        let vaultRef = acct.borrow<&FungibleToken.Vault>(from: vaultStoragePath)
            ?? panic("Could not borrow a reference to the owner's vault")
        
        let fund <- vaultRef.withdraw(amount: amount)

        lockerRef.lock(fund: <-fund, toChainId: toChainId , toAddress: toAddress)
    }
}