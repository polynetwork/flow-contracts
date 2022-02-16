import path from "path";
import { 
	emulator,
	init,
	shallPass,
	shallResolve,
	shallRevert,
} from "flow-js-testing";

import { deployCrossChainManager } from "../src/deploy";
import {
  initGenesisKeepers,
  pauseCCM,
  unpauseCCM,
  isCCMPaused,
  setChainId,
  getChainId,
} from "../src/setupCrossChainManager";
import {
  getDevSignerPublicKeys,
  shallThrow,
} from "../src/utils"
import { expect } from "chai";

// Increase timeout if your tests failing due to timeout
jest.setTimeout(50000);

describe("CrossChainManager.test.js", ()=>{
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "../../"); 
		// You can specify different port to parallelize execution of describe blocks
    const port = 8080; 
		// Setting logging flag to true will pipe emulator output to console
    const logging = false;
    
    await init(basePath, { port });
		await emulator.start(port, false);
		return await new Promise(r => setTimeout(r, 1000));
  });
  
 // Stop emulator, so it could be restarted
  afterEach(async () => {
    await emulator.stop();
		return await new Promise(r => setTimeout(r, 1000));
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

})
