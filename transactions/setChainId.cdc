import CrossChainManager from 0xb68073c0c84c26e2

transaction {
    prepare(acct: AuthAccount) {
        // --------- edit below ---------
        var newChainId: UInt64 = 999
        // --------- edit above ---------

        // don't edit below
        var adminPath = /private/CCMAdmin
        var adminRef = acct.getCapability(adminPath)
            .borrow<&CrossChainManager.Admin>() 
            ?? panic("fail to borrow admin reference")
        
        adminRef.setChainId(newChainId)
        assert(CrossChainManager.chainId == newChainId, 
            message: "check chainId set failed")
    }
}