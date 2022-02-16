import { mintFlow } from "flow-js-testing";
import { 
	// sendTransactionWithErrorRaised, 
	// executeScriptWithErrorRaised, 
	deployContractByNameWithErrorRaised,
    getCCMAdminAddress,
    getLockProxyAdminAddress,
    getExampleTokenAdminAddress
} from "./common"

export const deployZeroCopySink = async () => {
    const CCMAdmin = await getCCMAdminAddress();
    await mintFlow(CCMAdmin, "10.0");
    
	return deployContractByNameWithErrorRaised({ to: CCMAdmin, name: "ZeroCopySink" });
}

export const deployZeroCopySource = async () => {
    const CCMAdmin = await getCCMAdminAddress();
    await mintFlow(CCMAdmin, "10.0");
    
	return deployContractByNameWithErrorRaised({ to: CCMAdmin, name: "ZeroCopySource" });
}

export const deployCCUtils = async () => {
    const CCMAdmin = await getCCMAdminAddress();
    await mintFlow(CCMAdmin, "10.0");

    await deployZeroCopySink();

    await deployZeroCopySource();

    const addressMap = { 
		ZeroCopySink: CCMAdmin,
		ZeroCopySource: CCMAdmin,
	};

	return deployContractByNameWithErrorRaised({ to: CCMAdmin, name: "CCUtils", addressMap });
}

export const deployCrossChainManager = async () => {
    const CCMAdmin = await getCCMAdminAddress();
    await mintFlow(CCMAdmin, "10.0");

    await deployCCUtils();

    const addressMap = { 
		ZeroCopySink: CCMAdmin,
		ZeroCopySource: CCMAdmin,
        CCUtils: CCMAdmin
	};

    return deployContractByNameWithErrorRaised({ to: CCMAdmin, name: "CrossChainManager", addressMap });
}

// remember deploy CrossChainManager bofore deploy LockProxy
export const deployLockProxy = async () => {
    const CCMAdmin = await getCCMAdminAddress();
    const LockProxyAdmin = await getLockProxyAdminAddress();
    await mintFlow(LockProxyAdmin, "10.0");

    const addressMap = { 
		ZeroCopySink: CCMAdmin,
		ZeroCopySource: CCMAdmin,
        CrossChainManager: CCMAdmin,
        FungibleToken: "0xee82856bf20e2aa6"
	};

    return deployContractByNameWithErrorRaised({ to: LockProxyAdmin, name: "LockProxy", addressMap });
}

export const deployExampleToken = async () => {
    const ExampleTokenAdmin = await getExampleTokenAdminAddress();
    await mintFlow(ExampleTokenAdmin, "10.0");

    const addressMap = {
        FungibleToken: "0xee82856bf20e2aa6"
	};

    return deployContractByNameWithErrorRaised({ to: ExampleTokenAdmin, name: "ExampleToken", addressMap });
}
