import CrossChainManager from 0xCROSSCHAINMANAGER

pub fun main(name: String): String {
    // LockProxy  ==>  /public/polynetwork_4fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc3
    return CrossChainManager.nameToPathIndentifier(name)
}
