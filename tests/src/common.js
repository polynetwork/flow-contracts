import { getAccountAddress } from "flow-js-testing";
import { deployContractByName, executeScript, sendTransaction } from "flow-js-testing";

const UFIX64_PRECISION = 8;

export const toUFix64 = (value) => value.toFixed(UFIX64_PRECISION);

export const getCCMAdminAddress = async () => getAccountAddress("CCMAdmin");
export const getLockProxyAdminAddress = async () => getAccountAddress("LockProxyAdmin");
export const getExampleTokenAdminAddress = async () => getAccountAddress("ExampleTokenAdmin");
export const getUserAddress = async () => getAccountAddress("User");

export const sendTransactionWithErrorRaised = async (...props) => {
    const [resp, err] = await sendTransaction(...props);
    if (err) {
        throw err;
    }
    return resp;
}

export const executeScriptWithErrorRaised = async (...props) => {
    const [resp, err] = await executeScript(...props);
    if (err) {
        throw err;
    }
    return resp;
}

export const deployContractByNameWithErrorRaised = async (...props) => {
    const [resp, err] = await deployContractByName(...props);
    if (err) {
        throw err;
    }
    return resp;
}

export const basicTransformer = async (code) => {
    const CCMAdmin = await getCCMAdminAddress();
    const LockProxyAdmin = await getLockProxyAdminAddress();
    const ExampleTokenAdmin = await getExampleTokenAdminAddress();

    let modified = code.replace(
        /import\s+FungibleToken\s+from\s+0xFUNGIBLETOKEN/,
        "import FungibleToken from 0xee82856bf20e2aa6",
    );
    modified = modified.replace(
        /import\s+ExampleToken\s+from\s+0xEXAMPLETOKEN/,
        "import ExampleToken from "+ExampleTokenAdmin,
    );
    modified = code.replace(
        /import\s+ZeroCopySink\s+from\s+0xZEROCOPYSINK/,
        "import ZeroCopySink from "+CCMAdmin,
    );
    modified = code.replace(
        /import\s+CrossChainManager\s+from\s+0xCROSSCHAINMANAGER/,
        "import CrossChainManager from "+CCMAdmin,
    );
    modified = code.replace(
        /import\s+LockProxy\s+from\s+0xLOCKPROXY/,
        "import LockProxy from "+LockProxyAdmin,
    );

    return modified;
};