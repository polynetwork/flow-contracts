import ExampleToken from "../../contracts/ExampleToken.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"

transaction {
    prepare(acct: AuthAccount) {
        // edit below if you don't use default value
        // --------- edit below ---------
        var vaultStoragePath = /storage/exampleTokenVault
        var vaultBalancePath = /public/exampleTokenBalance
        var vaultReceiverPath = /public/exampleTokenReceiver 
        // --------- edit above ---------

        // don't edit below
        let vault <- ExampleToken.createEmptyVault()

        acct.save<@ExampleToken.Vault>(<-vault, to: vaultStoragePath)
        log("Empty vault stored, storagePath: ")
        log(vaultStoragePath)


        let receiverRef = 
        acct.link<&{FungibleToken.Receiver}>
            (vaultReceiverPath , target: vaultStoragePath)
        log("Receiver reference created, publicPath: ")
        log(vaultReceiverPath)

        assert(
            acct.getCapability<&{FungibleToken.Receiver}>(vaultReceiverPath).check(), 
            message: "Receiver Reference was not created correctly")


        let balanceRef = 
        acct.link<&{FungibleToken.Balance}>
            (vaultBalancePath , target: vaultStoragePath)
        log("Balance reference created, publicPath: ")
        log(vaultBalancePath)

        assert(
            acct.getCapability<&{FungibleToken.Balance}>(vaultBalancePath).check(), 
            message: "Balance Reference was not created correctly")
    }
}