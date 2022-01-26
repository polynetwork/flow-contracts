import CrossChainManager from 0xb68073c0c84c26e2

transaction {
    prepare(acct: AuthAccount) {
        // --------- edit below ---------
        var pubKeyList: [[UInt8]] = [
            "482acb6564b19b90653f6e9c806292e8aa83f78e7a9382a24a6efe41c0c06f39ef0a95ee60ad9213eb0be343b703dd32b12db32f098350cf3f4fc3bad6db23ce".decodeHex(),
            "8172918540b2b512eae1872a2a2e3a28d989c60d95dab8829ada7d7dd706d658df044eb93bbe698eff62156fc14d6d07b7aebfbc1a98ec4180b4346e67cc3fb0".decodeHex(),
            "8b8af6210ecfdcbcab22552ef8d8cf41c6f86f9cf9ab53d865741cfdb833f06b72fcc7e7d8b9e738b565edf42d8769fd161178432eadb2e446dd0a8785ba088f".decodeHex(),
            "679930a42aaf3c69798ca8a3f12e134c019405818d783d11748e039de8515988754f348293c65055f0f1a9a5e895e4e7269739e243a661fff801941352c38712".decodeHex(),
            "468dd1899ed2d1cc2b829882a165a0ecb6a745af0c72eb2982d66b4311b4ef73cff28a6492b076445337d8037c6c7be4d3ec9c4dbe8d7dc65d458181de7b5250".decodeHex(),
            "0011".decodeHex(),
            "0022".decodeHex()
            ]
        var toMerkleValueBs: [UInt8] = "".decodeHex()
        // --------- edit above ---------

        // don't edit below
        var adminPath = /private/CCMAdmin
        var adminRef = acct.getCapability(adminPath)
            .borrow<&CrossChainManager.Admin>() 
            ?? panic("fail to borrow admin reference")
        assert(adminRef.initGenesisKeepers(pubKeyList: pubKeyList),
            message: "fail to initGenesisKeepers")
        
    }
}