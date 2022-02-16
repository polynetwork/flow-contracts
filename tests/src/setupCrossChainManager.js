import { mintFlow } from "flow-js-testing";
import { 
	sendTransactionWithErrorRaised, 
	executeScriptWithErrorRaised, 
	deployContractByNameWithErrorRaised,
    getCCMAdminAddress,
    getLockProxyAdminAddress,
    getExampleTokenAdminAddress,
	basicTransformer
} from "./common"

export const initGenesisKeepers = async (publicKeyList) => {
	const name = "CrossChainManager/initGenesisKeepers";
	const args = [publicKeyList]
    const CCMAdmin = await getCCMAdminAddress();
	const signers = [CCMAdmin];
	const addressMap = { CrossChainManager: CCMAdmin }
    await mintFlow(CCMAdmin, "1.0");

	return sendTransactionWithErrorRaised({ name, args, signers, addressMap });
};

export const issueLicense = async (receiverAccount, receiverName, receiverPath) => {
	const name = "CrossChainManager/issueLicense";
	const args = [receiverAccount, receiverName, receiverPath]
    const CCMAdmin = await getCCMAdminAddress();
	const LockProxyAdmin = await getLockProxyAdminAddress();
	const signers = [CCMAdmin];
	const addressMap = { 
		CrossChainManager: CCMAdmin,
		LockProxy: LockProxyAdmin
	}
    await mintFlow(CCMAdmin, "1.0");

	return sendTransactionWithErrorRaised({ name, args, signers, addressMap });
};

export const pauseCCM = async () => {
	const name = "CrossChainManager/pauseCCM";
    const CCMAdmin = await getCCMAdminAddress();
	const signers = [CCMAdmin];
	const addressMap = { CrossChainManager: CCMAdmin }
    await mintFlow(CCMAdmin, "1.0");

	return sendTransactionWithErrorRaised({ name, signers, addressMap });
};

export const unpauseCCM = async () => {
	const name = "CrossChainManager/unpauseCCM";
    const CCMAdmin = await getCCMAdminAddress();
	const signers = [CCMAdmin];
	const addressMap = { CrossChainManager: CCMAdmin }
    await mintFlow(CCMAdmin, "1.0");

	return sendTransactionWithErrorRaised({ name, signers, addressMap });
};

export const setChainId = async (newChainId) => {
	const name = "CrossChainManager/setChainId";
	const args = [newChainId]
    const CCMAdmin = await getCCMAdminAddress();
	const signers = [CCMAdmin];
	const addressMap = { CrossChainManager: CCMAdmin }
    await mintFlow(CCMAdmin, "1.0");

	return sendTransactionWithErrorRaised({ name, args, signers, addressMap });
};

export const isCCMPaused = async () => {
	const name = "CrossChainManager/isCCMPaused";
	const args = [];
	const transformers = [basicTransformer];

	return executeScriptWithErrorRaised({ name, args, transformers });
};

export const getChainId = async () => {
	const name = "CrossChainManager/getChainId";
	const args = [];
	const transformers = [basicTransformer];

	return executeScriptWithErrorRaised({ name, args, transformers });
}

