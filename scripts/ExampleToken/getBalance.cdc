import FungibleToken from 0xFUNGIBLETOKEN

// import FungibleToken from 0xee82856bf20e2aa6 // on emulator
// import FungibleToken from 0x9a0766d93b6608b7 // on testnet
// import FungibleToken from 0xf233dcee88fe0abe // on mainnet

pub fun main(owner: Address): UFix64 {

    // edit below if you don't use default value
    // --------- edit below ---------
    var vaultPath = /public/exampleTokenBalance
    // --------- edit above ---------

    var acct = getAccount(owner)
    let balanceRef = acct.getCapability(vaultPath)
        .borrow<&{FungibleToken.Balance}>()
        ?? panic("Could not borrow a reference to the acct balance")

    return balanceRef.balance
}