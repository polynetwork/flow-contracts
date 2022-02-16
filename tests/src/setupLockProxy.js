import { mintFlow } from "flow-js-testing";
import { 
	sendTransactionWithErrorRaised, 
	executeScriptWithErrorRaised, 
	deployContractByNameWithErrorRaised,
    getCCMAdminAddress,
    getLockProxyAdminAddress,
    getExampleTokenAdminAddress,
	getUserAddress,
	basicTransformer
} from "./common"
import { issueLicense } from "./setupCrossChainManager";

export const createLocker = async () => {
	const name = "LockProxy/createLocker";
	const args = []
    const CCMAdmin = await getCCMAdminAddress();
	const LockProxyAdmin = await getLockProxyAdminAddress();
	const signers = [LockProxyAdmin];
	const addressMap = { 
		CrossChainManager: CCMAdmin,
		LockProxy: LockProxyAdmin
	}
    await mintFlow(LockProxyAdmin, "1.0");

	return sendTransactionWithErrorRaised({ name, args, signers ,addressMap });
};

export const issueLicenseForLocker = async () => {
	const LockProxyAdmin = await getLockProxyAdminAddress();
	const receiverAccount = sansPrefix(LockProxyAdmin)
	const receiverName = "LockProxy"
	const receiverPath = "/public/polynetwork_4fc2514492f4ec4dd924c68cdc0ddbdacc1d57411b457e59c38ba583e5ea3dc3"

	return issueLicense(receiverAccount, receiverName, receiverPath);
}

export const bindProxyHash = async (
    toChainId,
    targetProxyHash
) => {
	const name = "LockProxy/bindProxyHash";
	const args = [
		toChainId,
		targetProxyHash
	]
    const LockProxyAdmin = await getLockProxyAdminAddress();
	const signers = [LockProxyAdmin];
	const addressMap = { LockProxy: LockProxyAdmin }
    await mintFlow(LockProxyAdmin, "1.0");

	return sendTransactionWithErrorRaised({ name, args, signers ,addressMap });
};

export const bindAssetHash = async (
    fromTokenType,
    toChainId,
    toAssetHash
) => {
	const name = "LockProxy/bindAssetHash";
	const args = [
		fromTokenType,
		toChainId,
		toAssetHash
	]
    const LockProxyAdmin = await getLockProxyAdminAddress();
	const signers = [LockProxyAdmin];
	const addressMap = { LockProxy: LockProxyAdmin }
    await mintFlow(LockProxyAdmin, "1.0");

	return sendTransactionWithErrorRaised({ name, args, signers ,addressMap });
};

export const getExampleTokenId = async () => {
	const name = "ExampleToken/getIdentifier";
	const args = [];
	const transformers = [basicTransformer];

	return executeScriptWithErrorRaised({ name, args, transformers });
}

export const getExampleTokenIdUTF8 = async () => {
	const name = "ExampleToken/getIdentifierUTF8";
	const args = [];
	const transformers = [basicTransformer];

	return executeScriptWithErrorRaised({ name, args, transformers });
}

export const getLockProxyId = async () => {
	const name = "CrossChainManager/getLicenseId";
    const LockProxyAdmin = await getLockProxyAdminAddress();
	const args = [sansPrefix(LockProxyAdmin), "LockProxy"];
	const transformers = [basicTransformer];

	return executeScriptWithErrorRaised({ name, args, transformers });
}

export const sansPrefix = (address) => {
	if (address == null) return null;
	return address.replace(/^0x/, "");
};
