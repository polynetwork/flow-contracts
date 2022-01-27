# flow-contracts

Poly Network CrossChain Contracts on flow.

## Contracts

### 1. ZeroCopySink && ZeroCopySource

ZeroCopySink/ZeroCopySource is used to serialize/deserialize data

### 2. CCUtils

CCUtils is used to verify signatures && deserialize crossChain message

### 3. CrossChainManager

CrossChainManager is used as a cross-chain gateway. It can receive messages from other contracts/resources and send these messages to other chains.

Interface: 
+ Resources which wanna send cross-chain message via CrossChainMessage must implement **@LicenseStore** && **@MessageReceiver**
+ **@LicenseStore**: Receive and store **@License** 
+ **@MessageReceiver**: Recevie and handle **CrossChainMessageData** and **@CrossChainMessage**

Resource & Struct:
+ **CrossChainMessageData**: The message from source chain
+ **@CrossChainMessage**: @CrossChainMessage is used to verify the identity of CrossChainManager. Only CrossChainManager contract is able to create @CrossChainMessage.
+ **@License**: Used to verify the identity of buiness resources(buiness resources mean those resources who use CrossChainManager to deliver cross-chain messages)
+ **@CertificationAuthority**: Used to issue lincense to buiness resource.
+ **@Admin**: Used to manage the CrossChainManager contract

Funtion:
+ crossChain(): Buiness resources call this function to send cross-chain message.
+ verifySigAndExecuteTx(): Its called by relayer(realyer is a bot that relay transactions between different chains). Relayer relay data from relay chain to flow(or other chains) CrossChainManager, CrossChainManager will verify the data(In most case, it will verify both header, proof & signature, but flow do not support arbitrary signature verification & keccak256 now, so flow CrossChainManager only verify specially made signatures) and handle the data(call buiness resources based on data).

### 4. LockProxy

LockProxy is a FT cross-chain dapp. It receives FT from user on source-chain, and release corresponding asset to user on target-chain.

Resource:
+ **@Locker**: Locker receives vaults from user and send cross-chain message via CrossChainManager to LockProxy on target-chain. LockProxy also receive cross-chain message from LockProxy on other chain via CrossChainManager, and release FT to user.

Function:
+ @Locker.lock(): Asset cross-chain entry.
+ @Locker.unlock(): Asset cross-chain export.
+ registerReceiverPath(): For now, cadence can not transform **bytes(e.g.[UInt8])** to **Path** , so we need to use a map to convert. It can be removed when [#1211](https://github.com/onflow/cadence/pull/1211) release.

