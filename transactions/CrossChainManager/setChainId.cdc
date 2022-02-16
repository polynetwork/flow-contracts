import CrossChainManager from "../../contracts/CrossChainManager.cdc"

transaction(
    newChainId: UInt64
) {
    prepare(acct: AuthAccount) {
        // edit below if you don't use default value
        // --------- edit below ---------      
        var adminPath = /private/CCMAdmin 
        // --------- edit above ---------

        // don't edit below
        var adminRef = acct.getCapability(adminPath)
            .borrow<&CrossChainManager.Admin>() 
            ?? panic("fail to borrow admin reference")
        
        adminRef.setChainId(newChainId)
        assert(CrossChainManager.chainId == newChainId, 
            message: "check chainId set failed")
    }
}