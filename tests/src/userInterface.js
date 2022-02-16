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
import { 
	getExampleTokenIdUTF8,
	sansPrefix,
} from "./setupLockProxy"

export const registerPathInLockProxy = async (
    userVaultPublicPath,
    pathStr
) => {
	const name = "LockProxy/registerPathInLockProxy";
	const args = [
		userVaultPublicPath,
		pathStr
	]
    const LockProxyAdmin = await getLockProxyAdminAddress();
    const User = await getUserAddress();
	const signers = [User];
	const addressMap = { LockProxy: LockProxyAdmin }
    await mintFlow(User, "1.0");

	return sendTransactionWithErrorRaised({ name, args, signers ,addressMap });
};

export const createExampleTokenVaultToUser = async () => {
	const name = "ExampleToken/createEmptyVault";
	const args = []
    const ExampleTokenAdmin = await getExampleTokenAdminAddress();
    const User = await getUserAddress();
	const signers = [User];
	const addressMap = { 
		ExampleToken: ExampleTokenAdmin,
		FungibleToken: 0xee82856bf20e2aa6
	}
    await mintFlow(User, "1.0");

	return sendTransactionWithErrorRaised({ name, args, signers ,addressMap });
}

export const mintExampleTokenToUser = async (amount) => {
	const name = "ExampleToken/transferExampleToken";
    const ExampleTokenAdmin = await getExampleTokenAdminAddress();
    const User = await getUserAddress();
	const args = [User, amount]
	const signers = [ExampleTokenAdmin];
	const addressMap = { 
		ExampleToken: ExampleTokenAdmin,
		FungibleToken: 0xee82856bf20e2aa6
	}
    await mintFlow(User, "1.0");

	return sendTransactionWithErrorRaised({ name, args, signers ,addressMap });
}

export const deposit = async (
    vaultStoragePath,
    amount
) => {
	const name = "LockProxy/deposit";
    const LockProxyAdmin = await getLockProxyAdminAddress();
	const args = [
		LockProxyAdmin,
		vaultStoragePath,
		amount
	];
	const User = await getUserAddress();
	const signers = [User];
	const addressMap = { 
		LockProxy: LockProxyAdmin,
		FungibleToken: 0xee82856bf20e2aa6
	}
    await mintFlow(User, "1.0");

	return sendTransactionWithErrorRaised({ name, args, signers ,addressMap });
};

export const depositExampleToken = async (amount) => {
	var vaultStoragePath = "/storage/exampleTokenVault"
	return deposit(vaultStoragePath, amount)
};

export const lock = async (
	vaultStoragePath,
    toChainId,
    toAddress,
    amount
) => {
	const name = "LockProxy/lock";
    const LockProxyAdmin = await getLockProxyAdminAddress();
	const args = [
		LockProxyAdmin,
		vaultStoragePath,
		toChainId,
		toAddress,
		amount
	]
    const User = await getUserAddress();
	const signers = [User];
	const addressMap = { 
		LockProxy: LockProxyAdmin,
		FungibleToken: 0xee82856bf20e2aa6
	}
    await mintFlow(User, "1.0");

	return sendTransactionWithErrorRaised({ name, args, signers, addressMap });
};

export const lockExampleToken = async (
    toChainId,
    toAddress,
    amount
) => {
	var vaultStoragePath = "/storage/exampleTokenVault"
	return lock(vaultStoragePath, toChainId, toAddress, amount)
};

export const verifySigAndExecuteTx = async (
	sigs,
	_signers,
	toMerkleValueBs
) => {
	const name = "CrossChainManager/verifySigAndExecuteTx";
	const args = [
		sigs,
		_signers,
		toMerkleValueBs
	]
    const CCMAdmin = await getCCMAdminAddress();
    const User = await getUserAddress();
	const signers = [User];
	const addressMap = { CrossChainManager: CCMAdmin }
    await mintFlow(User, "1.0");

	return sendTransactionWithErrorRaised({ name, args, signers, limit: 9999, addressMap });
};

export const getCompositeAddress = async (addr, pathStr) => {
	const name = "LockProxy/getCompositeAddress";
	const args = [sansPrefix(addr), pathStr];
	const transformers = [basicTransformer];

	return executeScriptWithErrorRaised({ name, args, transformers });
};

export const getCompositeAddressForUser = async () => {
    const User = await getUserAddress();

	return getCompositeAddress(sansPrefix(User), "exampleTokenReceiver")
};

export const getLockerBalance = async (tokenType) => {
	const name = "LockProxy/getLockerBalance";
    const LockProxyAdmin = await getLockProxyAdminAddress();
	const args = [LockProxyAdmin, tokenType];
	const transformers = [basicTransformer];

	return executeScriptWithErrorRaised({ name, args, transformers });
};

export const getLockerBalanceForExampleToken = async () => {
	const tokenType = await getExampleTokenIdUTF8();

	return getLockerBalance(tokenType);
};

export const getExampleTokenBalanceOf = async (owner) => {
	const name = "ExampleToken/getBalance";
	const args = [owner];
	const transformers = [basicTransformer];

	return executeScriptWithErrorRaised({ name, args, transformers });
};

export const getExampleTokenBalanceOfUser = async () => {
	const User = await getUserAddress();

	return getExampleTokenBalanceOf(User);
}; 



