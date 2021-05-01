const hre = require('hardhat');

const REFLEXER_SAFE_MANAGER_ADDR = '0xEfe0B4cA532769a3AE758fD82E1426a03A94F185';
const ADAPTER_ADDRESS = '0x2D3cD7b81c93f188F3CB8aD87c8Acc73d6226e3A';

const safeCount = async (user) => {
    const ISAFEManager = await
    hre.ethers.getContractAt('ISAFEManager', REFLEXER_SAFE_MANAGER_ADDR);

    const safeCountResult = await ISAFEManager.safeCount(user);
    return safeCountResult.toNumber();
};

const lastSafeID = async (user) => {
    const ISAFEManager = await
    hre.ethers.getContractAt('ISAFEManager', REFLEXER_SAFE_MANAGER_ADDR);

    const lastID = await ISAFEManager.lastSAFEID(user);
    return lastID.toNumber();
};

const ownsSafe = async (safeID) => {
    const ISAFEManager = await
    hre.ethers.getContractAt('ISAFEManager', REFLEXER_SAFE_MANAGER_ADDR);

    const owner = await ISAFEManager.ownsSAFE(safeID);
    return owner;
};

const getSafeInfo = async (reflexerView, safeID) => {
    const info = await reflexerView.getSafeInfo(safeID);
    return info;
};

module.exports = {
    lastSafeID,
    safeCount,
    ownsSafe,
    getSafeInfo,
    REFLEXER_SAFE_MANAGER_ADDR,
    ADAPTER_ADDRESS,
};