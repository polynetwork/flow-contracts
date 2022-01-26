import FungibleToken from 0x9a0766d93b6608b7

// import FungibleToken from 0xee82856bf20e2aa6 // on emulator
// import FungibleToken from 0x9a0766d93b6608b7 // on testnet
// import FungibleToken from 0xf233dcee88fe0abe // on mainnet

pub fun main(): UFix64 {
    var vaultPath = /public/exampleTokenBalance
    var acct = getAccount(0xb68073c0c84c26e2)

    let balanceRef = acct.getCapability(vaultPath)
        .borrow<&{FungibleToken.Balance}>()
        ?? panic("Could not borrow a reference to the acct balance")

    return balanceRef.balance
}