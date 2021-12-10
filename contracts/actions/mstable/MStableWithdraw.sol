// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "contracts/interfaces/mstable/IBoostedVaultWithLockup.sol";
import "contracts/interfaces/mstable/ImAsset.sol";
import "contracts/interfaces/mstable/ISavingsContractV2.sol";
import "contracts/utils/TokenUtils.sol";
import "../ActionBase.sol";

contract MStableWithdraw is ActionBase {
    using TokenUtils for address;

    struct Params {
        address bAsset;         // base asset to withdraw
        address mAsset;         // the corresponding meta asset
        address saveAddress;    // save contract address for the mAsset (imAsset address)
        address vaultAddress;   // vault contract address for the imAsset (imAssetVault address), unused if unstake == false
        address from;           // address from where to pull the imAsset, unused if unstake == true
        address to;             // address that will receive the bAsset
        uint256 amount;         // amount of (unstake ? imAssetVault : imAsset) to redeem
        uint256 minOut;         // minimum amount of bAsset to accept
        bool unstake;           // unstake flag
    }

    function executeAction(
        bytes[] memory _callData,
        bytes[] memory _subData,
        uint8[] memory _paramMapping,
        bytes32[] memory _returnValues
    ) public payable override returns (bytes32) {
        Params memory params = parseInputs(_callData);
        params.bAsset = _parseParamAddr(params.bAsset, _paramMapping[0], _subData, _returnValues);
        params.mAsset = _parseParamAddr(params.mAsset, _paramMapping[1], _subData, _returnValues);
        params.saveAddress = _parseParamAddr(params.saveAddress, _paramMapping[2], _subData, _returnValues);
        params.vaultAddress = _parseParamAddr(params.vaultAddress, _paramMapping[3], _subData, _returnValues);
        params.from = _parseParamAddr(params.from, _paramMapping[4], _subData, _returnValues);
        params.to = _parseParamAddr(params.to, _paramMapping[5], _subData, _returnValues);
        params.amount = _parseParamUint(params.amount, _paramMapping[6], _subData, _returnValues);
        params.minOut = _parseParamUint(params.minOut, _paramMapping[7], _subData, _returnValues);
        params.unstake = _parseParamUint(params.unstake ? 1 : 0, _paramMapping[8], _subData, _returnValues) == 0 ? false : true;
        
        uint256 withdrawn = _mStableWithdraw(params);
        return bytes32(withdrawn);
    }

    function executeActionDirect(bytes[] memory _callData) public payable override {
        Params memory params = parseInputs(_callData);
        _mStableWithdraw(params);
    }

    /// @notice Action that withdraws the base asset from the Savings Contract, or if unstaking, from the Savings Vault
    function _mStableWithdraw(Params memory _params) internal returns (uint256 withdrawn) {
        // _params.to = 0 will revert
        // _params.amount = 0 will revert
        if (_params.unstake) {
            if (_params.amount == type(uint256).max) {
                _params.amount = IBoostedVaultWithLockup(_params.vaultAddress).rawBalanceOf(address(this));
            }
            IBoostedVaultWithLockup(_params.vaultAddress).withdraw(_params.amount);
        } else {
            if (_params.amount == type(uint256).max) {
                _params.amount = _params.saveAddress.getBalance(_params.from);
            }
            _params.saveAddress.pullTokensIfNeeded(_params.from, _params.amount);
        }

        uint256 mAssetRedeemedAmount = ISavingsContractV2(_params.saveAddress).redeemCredits(_params.amount);
        withdrawn = ImAsset(_params.mAsset).redeem(_params.bAsset, mAssetRedeemedAmount, _params.minOut, _params.to);

        logger.Log(
            address(this),
            msg.sender,
            "MStableWithdraw",
            abi.encode(
                _params,
                withdrawn
            )
        );
    }

    function actionType() public pure override returns (uint8) {
        return uint8(ActionType.STANDARD_ACTION);
    }

    function parseInputs(bytes[] memory _callData)
        internal
        pure
        returns (
            Params memory params
        )
    {
        params = abi.decode(_callData[0], (Params));
    }
}