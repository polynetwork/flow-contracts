import CrossChainManager from "../../contracts/CrossChainManager.cdc"

transaction {
    prepare(acct: AuthAccount) {
        // edit below if you don't use default value
        // --------- edit below ---------      
        var adminPath = /private/CCMAdmin 
        // --------- edit above ---------

        var adminRef = acct.getCapability(adminPath)
            .borrow<&CrossChainManager.Admin>() 
            ?? panic("fail to borrow admin reference")
        adminRef.pause()
        assert(CrossChainManager.paused,
            message: "CCM not paused correctly")
    }
}