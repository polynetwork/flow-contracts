import ExampleToken from 0xf8d6e0586b0a20c7

pub fun main(): String {
    let emptyVault <- ExampleToken.createEmptyVault()
    let id = emptyVault.getType().identifier
    destroy emptyVault
    return id
}