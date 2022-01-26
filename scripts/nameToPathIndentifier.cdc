import CrossChainManager from 0xf8d6e0586b0a20c7

pub fun main(): String {
    var name = "invalid"
    // LockProxy  ==>  /public/polynetwork_4fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc3
    return CrossChainManager.nameToPathIndentifier(name)
}
 