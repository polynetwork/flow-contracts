import LockProxy from 0xb68073c0c84c26e2
import CrossChainManager from 0xb68073c0c84c26e2

transaction {
    prepare(acct: AuthAccount) {
        // --------- edit below ---------
        var userReceiverPublicPath: PublicPath = /public/exampleTokenReceiver 
        var pathStr: String = "exampleTokenReceiver"
        var sigs: [[UInt8]] = [
            "8419515245886945da6743a23aae5444f056a16613403c799b628476054ed2eb5e38c28df001ed4acdaf0bb219b2ddd8e25c4469ef6d78307761d7ea9a652729".decodeHex(),
            "3f2931abb12dbe42f549e6051dd487efe509bdb2f0207fe46e1e78c0cb5b1a74ac664a925c376181b1993003ed9beb9ad539f9c4da5c44184e48e3cea2aa0017".decodeHex(),
            "2c6f5aeeec35ec47e425a8626bc6fd8a9e084575c001a260005ae4567eef90f53cc9cef14ec3e2553fe341dc0e2521388c68e5be6774411a0ac81e420145574a".decodeHex(),
            "48b4efb56f2e83e669d6da8b3c6c27a6ece57f91d8b7e07eb57843a64918eda868b3bc2ab7bd74a5f430bd26225b92ec2c266b264df7067c40ecc9f1046fe3bb".decodeHex(),
            "459417e285c2996e0c0875791433718171840ddf12cd266993960225e83014654a8b036b2f83cc9f3a1de50052d602b2b6daa6ec263cdf448f388cba8039c3c3".decodeHex()
            ]
        var signers: [[UInt8]] = [
            "482acb6564b19b90653f6e9c806292e8aa83f78e7a9382a24a6efe41c0c06f39ef0a95ee60ad9213eb0be343b703dd32b12db32f098350cf3f4fc3bad6db23ce".decodeHex(),
            "8172918540b2b512eae1872a2a2e3a28d989c60d95dab8829ada7d7dd706d658df044eb93bbe698eff62156fc14d6d07b7aebfbc1a98ec4180b4346e67cc3fb0".decodeHex(),
            "8b8af6210ecfdcbcab22552ef8d8cf41c6f86f9cf9ab53d865741cfdb833f06b72fcc7e7d8b9e738b565edf42d8769fd161178432eadb2e446dd0a8785ba088f".decodeHex(),
            "679930a42aaf3c69798ca8a3f12e134c019405818d783d11748e039de8515988754f348293c65055f0f1a9a5e895e4e7269739e243a661fff801941352c38712".decodeHex(),
            "468dd1899ed2d1cc2b829882a165a0ecb6a745af0c72eb2982d66b4311b4ef73cff28a6492b076445337d8037c6c7be4d3ec9c4dbe8d7dc65d458181de7b5250".decodeHex()
            ]
        var toMerkleValueBs: [UInt8] = "20154fd3afb1d53a76507617251748b19f1c0268756cd0c6839ad8594cfea60ec7e70300000000000001012099d31ffd2c6e8deddb2b9724d4d61b4e1b74423a1a0e22e236b585cfe56021c429e2264cc8c07380b6204fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc3e70300000000000029e2264cc8c07380b6204fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc306756e6c6f636b6425412e623638303733633063383463323665322e4578616d706c65546f6b656e2e5661756c741de2264cc8c07380b6146578616d706c65546f6b656e52656365697665720800000000000000000000000000000000000000000000000000000000000000".decodeHex()
        // --------- edit above ---------

        // don't edit below
        let p = LockProxy.pathStrMap[String.encodeHex(pathStr.utf8)]
        if (p == nil) {
            LockProxy.registerReceiverPath(pathStr: pathStr, path: userReceiverPublicPath)
        }
        assert(LockProxy.pathStrMap[String.encodeHex(pathStr.utf8)]!.toString() == userReceiverPublicPath.toString(), 
            message: "fail to regesiter receiver path")

        assert(CrossChainManager.verifySigAndExecuteTx(sigs: sigs, signers: signers, toMerkleValueBs: toMerkleValueBs),
            message: "fail to verifySigAndExecuteTx")
    }
}