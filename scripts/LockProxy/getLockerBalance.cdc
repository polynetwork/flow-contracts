import LockProxy from 0xLOCKPROXY

pub fun main(lockerAccount: Address, tokenType: String): UFix64 {
    // edit below if you don't use default value
    // --------- edit below ---------
    var lockerPublicPath = /public/polynetwork_4fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc3   
    // --------- edit above ---------

    let lockerRef = getAccount(lockerAccount).getCapability<&LockProxy.Locker{LockProxy.Balance}>(lockerPublicPath).borrow()
        ?? panic("fail to borrow Locker")
    
    return lockerRef.getBalanceFor(tokenType)
}