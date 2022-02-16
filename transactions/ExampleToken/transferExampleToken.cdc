import ExampleToken from "../../contracts/ExampleToken.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"

transaction(
    recipient: Address,
    amount: UFix64
) {
    prepare(acct: AuthAccount) {
        // edit below if you don't use default value
        // --------- edit below ---------
        var vaultStoragePath = /storage/exampleTokenVault
        var vaultBalancePath = /public/exampleTokenBalance
        var vaultReceiverPath = /public/exampleTokenReceiver 
        // --------- edit above ---------

        // don't edit below
        let vaultRef = acct.borrow<&ExampleToken.Vault>(from: vaultStoragePath)
            ?? panic("Could not borrow a reference to the owner's vault")

        let temporaryVault <- vaultRef.withdraw(amount: amount)
        
        let receiverRef = getAccount(recipient).getCapability(vaultReceiverPath)
                            .borrow<&{FungibleToken.Receiver}>()
                            ?? panic("Could not borrow a reference to the receiver")
        
        receiverRef.deposit(from: <- temporaryVault)

        log("Transfer succeeded!")
    }
}