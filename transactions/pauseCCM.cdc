import CrossChainManager from 0xb68073c0c84c26e2

transaction {
    prepare(acct: AuthAccount) {
        var adminPath = /private/CCMAdmin
        var adminRef = acct.getCapability(adminPath)
            .borrow<&CrossChainManager.Admin>() 
            ?? panic("fail to borrow admin reference")
        adminRef.pause()
        assert(CrossChainManager.paused,
            message: "CCM not paused correctly")
    }
}