import FungibleToken from "./flowFT/FungibleToken.cdc"

pub contract FeeManager {
    
    pub event FeePayed(tag: String, feeToken: String, amount: UFix64)

    access(self) var drawers: @{String: FungibleToken.Vault}

    pub resource Admin {
        pub fun withdraw(amount: UFix64, tokenType: String): @FungibleToken.Vault {
            return FeeManager.withdrawFromDrawer(amount: UFix64, tokenType: String)
        }
    }

    pub fun payFee(tag: String, fund: @FungibleToken.Vault) {
        var feeToken = fund.getType().identifier
        var amount = fund.balance
        self.deposit(<-fund)
        emit FeePayed(tag: tag, feeToken: feeToken, amount: amount)
    }

    pub fun getBalanceFor(_ tokenType: String): UFix64 {
        var vaultOpt: @FungibleToken.Vault? <- nil
        vaultOpt <-> self.drawers[tokenType]
        var balance: UFix64 = UFix64(0)
        if vaultOpt == nil {
            destroy vaultOpt
            balance = UFix64(0)
        } else {
            var vault: @FungibleToken.Vault <- vaultOpt!
            balance = vault.balance
            self.drawers[tokenType] <-! vault
        }
        return balance
    }

    access(self) fun withdrawFromDrawer(amount: UFix64, tokenType: String): @FungibleToken.Vault {
        var drawerOpt: @FungibleToken.Vault? <- nil
        drawerOpt <-> self.drawers[tokenType]
        var drawer <- drawerOpt!
        var res <- drawer.withdraw(amount: amount)
        self.drawers[tokenType] <-! drawer
        return <-res
    }


    access(self) fun deposit(_ fund: @FungibleToken.Vault) {
        var tokenType = fund.getType().identifier
        var vaultOpt: @FungibleToken.Vault? <- nil
        vaultOpt <-> self.drawers[tokenType]
        if vaultOpt == nil {
            self.drawers[tokenType] <-! fund
            destroy vaultOpt
        } else {
            fund.deposit(from: <-vaultOpt!)
            self.drawers[tokenType] <-! fund
        }
    }

    init() {
        self.drawer <- {}
        self.account.save(<-create Admin(), to: /storage/FeeManagerAdmin)
    }
}