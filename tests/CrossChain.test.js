import path from "path";
import { 
	emulator,
	init,
	shallPass,
} from "flow-js-testing";

import { 
  deployCrossChainManager,
  deployLockProxy,
  deployExampleToken,
 } from "./src/deploy";
import {
  initGenesisKeepers,
  pauseCCM,
  unpauseCCM,
  isCCMPaused,
  setChainId,
  getChainId,
} from "./src/setupCrossChainManager";
import {
  createLocker,
  issueLicenseForLocker,
  bindProxyHash,
  bindAssetHash,
  getLockProxyId,
  getExampleTokenId,
  getExampleTokenIdUTF8
} from "./src/setuplockProxy";
import {
  registerPathInLockProxy,
  depositExampleToken,
  lockExampleToken,
  verifySigAndExecuteTx,
  getLockerBalanceForExampleToken,
  createExampleTokenVaultToUser,
  getCompositeAddressForUser,
  mintExampleTokenToUser,
  getExampleTokenBalanceOfUser
} from "./src/userInterface";
import {
  getArgs,
  getToMerkleValueBs,
  getDevSignerPublicKeys,
  generateSignatures,
  genrateFakeSignatures,
  shallThrow,
  addTag
} from "./src/utils"
import { expect } from "chai";

// Increase timeout if your tests failing due to timeout
jest.setTimeout(10000);

describe("CrossChain", ()=>{
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "../"); 
    const port = 8080; 
    const logging = false;
    await init(basePath, { port });
    return emulator.start(port, logging);
  });
  
 // Stop emulator, so it could be restarted
  afterEach(async () => {
    return emulator.stop();
  });
  
  test("should deploy CrossChainManager, CCUtils, ZeroCopySink, ZeroCopySource contract", async () => {
    await deployCrossChainManager();
  })

  test("should pause and unpause CrossChainManager", async () => {
    await deployCrossChainManager();
    expect(await isCCMPaused()).to.equal(false);
    await shallPass(pauseCCM());
    expect(await isCCMPaused()).to.equal(true);
    await shallPass(unpauseCCM());
    expect(await isCCMPaused()).to.equal(false);
  })

  test("should setChainId", async () => {
    await deployCrossChainManager();

    expect(await getChainId()).to.equal(999);

    await shallPass(setChainId(99));

    expect(await getChainId()).to.equal(99);
  })

  test("should initGenesisKeepers", async () => {
    await deployCrossChainManager();
    const keepers = await getDevSignerPublicKeys();
    await shallPass(initGenesisKeepers(keepers));
  })

  test("fail to initGenesisKeepers if contract is paused", async () => {
    await deployCrossChainManager();
    const keepers = await getDevSignerPublicKeys();
    await shallPass(pauseCCM());
    shallThrow(initGenesisKeepers(keepers));
    // await shallRevert(initGenesisKeepers(keepers));
  })

  test("should deploy LockProxy & ExampleToken", async () => {
    await deployCrossChainManager();
    await deployLockProxy();
    await deployExampleToken();
  })
  
  test("should create empty locker", async () => {
    await deployCrossChainManager();
    await deployLockProxy();
    await shallPass(createLocker());
  })
  
  test("should bindProxyHash", async () => {
    await deployCrossChainManager();
    await deployLockProxy();
    await shallPass(createLocker());
    let toChainId = await getChainId(); 
    let targetProxyHash = await getLockProxyId();
    await shallPass(bindProxyHash(toChainId, targetProxyHash));
  })
  
  test("should bindAssetHash", async () => {
    await deployCrossChainManager();
    await deployLockProxy();
    await deployExampleToken();
    await shallPass(createLocker());
    let fromTokenType = await getExampleTokenId();
    let toChainId = await getChainId();
    let toAssetHash = await getExampleTokenIdUTF8();
    await shallPass(bindAssetHash(fromTokenType, toChainId, toAssetHash));
  })
  
  test("should register path in LockProxy", async () => {
    await deployCrossChainManager();
    await deployLockProxy();
    await shallPass(createLocker());
    let userVaultPublicPath = "/public/exampleTokenReceiver"
    let pathStr = "exampleTokenReceiver"
    await shallPass(registerPathInLockProxy(userVaultPublicPath, pathStr));
  })
  
  test("fail to register path with invaild parameters", async () => {
    await deployCrossChainManager();
    await deployLockProxy();
    await shallPass(createLocker());
    let userVaultPublicPath = "/public/fakePath"
    let pathStr = "exampleTokenReceiver"
    await shallThrow(registerPathInLockProxy(userVaultPublicPath, pathStr));
  })

  test("should deposit 150 $ExampleToken$ to Locker ", async () => {
    await deployCrossChainManager();
    await deployLockProxy();
    await deployExampleToken();
    await shallPass(createLocker());

    await shallPass(createExampleTokenVaultToUser());
    await shallPass(mintExampleTokenToUser(170));

    expect(await getExampleTokenBalanceOfUser()).to.equal("170.00000000");
    expect(await getLockerBalanceForExampleToken()).to.equal("0.00000000");

    await shallPass(depositExampleToken(100));
    expect(await getExampleTokenBalanceOfUser()).to.equal("70.00000000");
    expect(await getLockerBalanceForExampleToken()).to.equal("100.00000000");

    await shallPass(depositExampleToken(50));
    expect(await getLockerBalanceForExampleToken()).to.equal("150.00000000");
    expect(await getExampleTokenBalanceOfUser()).to.equal("20.00000000");
  })

  test("should lock 30 $ExampleToken$ to Locker", async () => {
    // deploy
    await deployCrossChainManager();
    await deployLockProxy();
    await deployExampleToken();
    await shallPass(createLocker());

    // issueLicense
    await shallPass(issueLicenseForLocker());

    // bindProxy
    let toChainId = await getChainId(); 
    let targetProxyHash = await getLockProxyId();
    await shallPass(bindProxyHash(toChainId, targetProxyHash));

    // bindAssetHash
    let fromTokenType = await getExampleTokenId();
    let toAssetHash = await getExampleTokenIdUTF8();
    await shallPass(bindAssetHash(fromTokenType, toChainId, toAssetHash));

    await shallPass(createExampleTokenVaultToUser());
    await shallPass(mintExampleTokenToUser(170));

    expect(await getExampleTokenBalanceOfUser()).to.equal("170.00000000");
    expect(await getLockerBalanceForExampleToken()).to.equal("0.00000000");

    let toAddress = await getCompositeAddressForUser();
    await shallPass(lockExampleToken(toChainId, toAddress, 30));
    expect(await getExampleTokenBalanceOfUser()).to.equal("140.00000000");
    expect(await getLockerBalanceForExampleToken()).to.equal("30.00000000");
  })

  test("fail to lock if Locker do not have license", async () => {
    await deployCrossChainManager();
    await deployLockProxy();
    await deployExampleToken();
    await shallPass(createLocker());

    // bindProxy
    let toChainId = await getChainId(); 
    let targetProxyHash = await getLockProxyId();
    await shallPass(bindProxyHash(toChainId, targetProxyHash));

    // bindAssetHash
    let fromTokenType = await getExampleTokenId();
    let toAssetHash = await getExampleTokenIdUTF8();
    await shallPass(bindAssetHash(fromTokenType, toChainId, toAssetHash));

    await shallPass(createExampleTokenVaultToUser());
    await shallPass(mintExampleTokenToUser(170));

    let toAddress = await getCompositeAddressForUser();
    await shallThrow(lockExampleToken(toChainId, toAddress, 30));
  })

  test("fail to lock if toProxy is not bind", async () => {
    await deployCrossChainManager();
    await deployLockProxy();
    await deployExampleToken();
    await shallPass(createLocker());

    // issueLicense
    await shallPass(issueLicenseForLocker());

    // bindAssetHash
    let toChainId = await getChainId(); 
    let fromTokenType = await getExampleTokenId();
    let toAssetHash = await getExampleTokenIdUTF8();
    await shallPass(bindAssetHash(fromTokenType, toChainId, toAssetHash));

    await shallPass(createExampleTokenVaultToUser());
    await shallPass(mintExampleTokenToUser(170));

    let toAddress = await getCompositeAddressForUser();
    await shallThrow(lockExampleToken(toChainId, toAddress, 30));
  })

  test("fail to lock if toAssetHash is not bind", async () => {
    await deployCrossChainManager();
    await deployLockProxy();
    await deployExampleToken();
    await shallPass(createLocker());

    // issueLicense
    await shallPass(issueLicenseForLocker());

    // bindProxy
    let toChainId = await getChainId(); 
    let targetProxyHash = await getLockProxyId();
    await shallPass(bindProxyHash(toChainId, targetProxyHash));

    await shallPass(createExampleTokenVaultToUser());
    await shallPass(mintExampleTokenToUser(170));

    let toAddress = await getCompositeAddressForUser();
    await shallThrow(lockExampleToken(toChainId, toAddress, 30));
  })

  test("fail to relay one single cross_chain message twice", async () => {
    // deploy
    await deployCrossChainManager();
    const keepers = await getDevSignerPublicKeys();
    await initGenesisKeepers(keepers);
    await deployLockProxy();
    await deployExampleToken();
    await shallPass(createLocker());

    // issueLicense
    await shallPass(issueLicenseForLocker());

    // bindProxy
    let toChainId = await getChainId(); 
    let targetProxyHash = await getLockProxyId();
    await shallPass(bindProxyHash(toChainId, targetProxyHash));

    // bindAssetHash
    let fromTokenType = await getExampleTokenId();
    let toAssetHash = await getExampleTokenIdUTF8();
    await shallPass(bindAssetHash(fromTokenType, toChainId, toAssetHash));
    
    // send some example token to user
    await shallPass(createExampleTokenVaultToUser());
    await shallPass(mintExampleTokenToUser(270));
    await shallPass(depositExampleToken(100));
    expect(await getExampleTokenBalanceOfUser()).to.equal("170.00000000");
    expect(await getLockerBalanceForExampleToken()).to.equal("100.00000000");

    // lock
    let toAddress = await getCompositeAddressForUser();
    let amount = 30.0
    await shallPass(lockExampleToken(toChainId, toAddress, amount));
    expect(await getExampleTokenBalanceOfUser()).to.equal("140.00000000");
    expect(await getLockerBalanceForExampleToken()).to.equal("130.00000000");

    // register receiver path
    let userVaultPublicPath = "/public/exampleTokenReceiver"
    let pathStr = "exampleTokenReceiver"
    await shallPass(registerPathInLockProxy(userVaultPublicPath, pathStr));

    // simulate generation of data from relay-chain
    //  from and to contract/chainId is the same because we are testing flow >-to-> flow crosschain
    let fromChainId = toChainId 
    let fromContract = targetProxyHash 
    // arbitrarily constructed polyTxHash/flowTxHash/crossChainId for test
    let polyTxHash = "706f6c79547848617368"
    let flowTxHash = "666c6f77547848617368"
    let crossChainId = "63726f7373436861696e4964"
    let method = "756e6c6f636b" // "unlock".utf8
    let args = await getArgs(toAssetHash, toAddress, amount)
    let toMerkleValueBs = await getToMerkleValueBs(
      polyTxHash,
      fromChainId,
      flowTxHash,
      crossChainId,
      fromContract,
      toChainId,
      targetProxyHash,
      method,
      args
    )

    // generate signatures
    let sigData = await addTag(toMerkleValueBs)
    let [sigs, signers] = await generateSignatures(sigData)

    // verifySigAndExecuteTx , user will receiver the asset
    await shallPass(verifySigAndExecuteTx(sigs, signers, toMerkleValueBs));
    await shallThrow(verifySigAndExecuteTx(sigs, signers, toMerkleValueBs));
    expect(await getExampleTokenBalanceOfUser()).to.equal("170.00000000");
    expect(await getLockerBalanceForExampleToken()).to.equal("100.00000000");
  })

  test("fail to relay cross_chain message which has fake signatures", async () => {
    // deploy
    await deployCrossChainManager();
    const keepers = await getDevSignerPublicKeys();
    await initGenesisKeepers(keepers);
    await deployLockProxy();
    await deployExampleToken();
    await shallPass(createLocker());

    // issueLicense
    await shallPass(issueLicenseForLocker());

    // bindProxy
    let toChainId = await getChainId(); 
    let targetProxyHash = await getLockProxyId();
    await shallPass(bindProxyHash(toChainId, targetProxyHash));

    // bindAssetHash
    let fromTokenType = await getExampleTokenId();
    let toAssetHash = await getExampleTokenIdUTF8();
    await shallPass(bindAssetHash(fromTokenType, toChainId, toAssetHash));
    
    // send some example token to user
    await shallPass(createExampleTokenVaultToUser());
    await shallPass(mintExampleTokenToUser(170));
    expect(await getExampleTokenBalanceOfUser()).to.equal("170.00000000");
    expect(await getLockerBalanceForExampleToken()).to.equal("0.00000000");

    // lock
    let toAddress = await getCompositeAddressForUser();
    let amount = 30.0
    await shallPass(lockExampleToken(toChainId, toAddress, amount));
    expect(await getExampleTokenBalanceOfUser()).to.equal("140.00000000");
    expect(await getLockerBalanceForExampleToken()).to.equal("30.00000000");

    // register receiver path
    let userVaultPublicPath = "/public/exampleTokenReceiver"
    let pathStr = "exampleTokenReceiver"
    await shallPass(registerPathInLockProxy(userVaultPublicPath, pathStr));

    // simulate generation of data from relay-chain
    //  from and to contract/chainId is the same because we are testing flow >-to-> flow crosschain
    let fromChainId = toChainId 
    let fromContract = targetProxyHash 
    // arbitrarily constructed polyTxHash/flowTxHash/crossChainId for test
    let polyTxHash = "706f6c79547848617368"
    let flowTxHash = "666c6f77547848617368"
    let crossChainId = "63726f7373436861696e4964"
    let method = "756e6c6f636b" // "unlock".utf8
    let args = await getArgs(toAssetHash, toAddress, amount)
    let toMerkleValueBs = await getToMerkleValueBs(
      polyTxHash,
      fromChainId,
      flowTxHash,
      crossChainId,
      fromContract,
      toChainId,
      targetProxyHash,
      method,
      args
    )

    // generate signatures
    let sigData = await addTag(toMerkleValueBs)
    let [sigs, signers] = await genrateFakeSignatures(sigData)

    // verifySigAndExecuteTx , user will receiver the asset
    await shallThrow(verifySigAndExecuteTx(sigs, signers, toMerkleValueBs));
    expect(await getExampleTokenBalanceOfUser()).to.equal("140.00000000");
    expect(await getLockerBalanceForExampleToken()).to.equal("30.00000000");
  })

  test("should receiver 30 $ExampleToken$ from Locker", async () => {
    // deploy
    await deployCrossChainManager();
    const keepers = await getDevSignerPublicKeys();
    await initGenesisKeepers(keepers);
    await deployLockProxy();
    await deployExampleToken();
    await shallPass(createLocker());

    // issueLicense
    await shallPass(issueLicenseForLocker());

    // bindProxy
    let toChainId = await getChainId(); 
    let targetProxyHash = await getLockProxyId();
    await shallPass(bindProxyHash(toChainId, targetProxyHash));

    // bindAssetHash
    let fromTokenType = await getExampleTokenId();
    let toAssetHash = await getExampleTokenIdUTF8();
    await shallPass(bindAssetHash(fromTokenType, toChainId, toAssetHash));
    
    // send some example token to user
    await shallPass(createExampleTokenVaultToUser());
    await shallPass(mintExampleTokenToUser(170));
    expect(await getExampleTokenBalanceOfUser()).to.equal("170.00000000");
    expect(await getLockerBalanceForExampleToken()).to.equal("0.00000000");

    // lock
    let toAddress = await getCompositeAddressForUser();
    let amount = 30.0
    await shallPass(lockExampleToken(toChainId, toAddress, amount));
    expect(await getExampleTokenBalanceOfUser()).to.equal("140.00000000");
    expect(await getLockerBalanceForExampleToken()).to.equal("30.00000000");

    // register receiver path
    let userVaultPublicPath = "/public/exampleTokenReceiver"
    let pathStr = "exampleTokenReceiver"
    await shallPass(registerPathInLockProxy(userVaultPublicPath, pathStr));

    // simulate generation of data from relay-chain
    //  from and to contract/chainId is the same because we are testing flow >-to-> flow crosschain
    let fromChainId = toChainId 
    let fromContract = targetProxyHash 
    // arbitrarily constructed polyTxHash/flowTxHash/crossChainId for test
    let polyTxHash = "706f6c79547848617368"
    let flowTxHash = "666c6f77547848617368"
    let crossChainId = "63726f7373436861696e4964"
    let method = "756e6c6f636b" // "unlock".utf8
    let args = await getArgs(toAssetHash, toAddress, amount)
    let toMerkleValueBs = await getToMerkleValueBs(
      polyTxHash,
      fromChainId,
      flowTxHash,
      crossChainId,
      fromContract,
      toChainId,
      targetProxyHash,
      method,
      args
    )

    // generate signatures
    let sigData = await addTag(toMerkleValueBs)
    let [sigs, signers] = await generateSignatures(sigData)

    // verifySigAndExecuteTx , user will receiver the asset
    await shallPass(verifySigAndExecuteTx(sigs, signers, toMerkleValueBs));
    expect(await getExampleTokenBalanceOfUser()).to.equal("170.00000000");
    expect(await getLockerBalanceForExampleToken()).to.equal("0.00000000");
  })

})
