import CrossChainManager from "../../contracts/CrossChainManager.cdc"

transaction(
    pubKeyStrList: [String]
) {
    prepare(acct: AuthAccount) {
        // edit below if you don't use default value
        // --------- edit below ---------      
        var adminPath = /private/CCMAdmin 
        // --------- edit above ---------

        var pubKeyList: [[UInt8]] = []
        for pk in pubKeyStrList {
            pubKeyList.append(pk.decodeHex())
        }
        
        var adminRef = acct.getCapability(adminPath)
            .borrow<&CrossChainManager.Admin>() 
            ?? panic("fail to borrow admin reference")
        assert(adminRef.initGenesisKeepers(pubKeyList),
            message: "fail to initGenesisKeepers")
        
    }
}