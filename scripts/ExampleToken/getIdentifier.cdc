import ExampleToken from 0xEXAMPLETOKEN

pub fun main(): String {
    let emptyVault <- ExampleToken.createEmptyVault()
    let id = emptyVault.getType().identifier
    destroy emptyVault
    return id
}