// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../interfaces/IFLAction.sol";
import "../../core/Subscriptions.sol";

contract FLTaker is IFLAction {

    Subscriptions public constant subscriptions = Subscriptions(0x76a185a4f66C0d09eBfbD916e0AD0f1CDF6B911b);
    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    function executeAction(uint _actionId, bytes memory _callData) override public returns (bytes memory) {

        (uint amount, address token, uint8 flType) = parseParamData(_callData);

        // if (_actionId != 0) {
        //     Subscriptions.Action memory a = subscriptions.getAction(_actionId);
        // }

        logger.Log(address(this), msg.sender, "FLTaker", abi.encode(amount, token, flType));

        return abi.encode(amount, token, flType);
    }

    function parseSubData(bytes memory _data) public pure returns (uint amount,address token,uint8 flType) {
        (amount, token, flType) = abi.decode(_data,(uint256,address,uint8));
    }

    function parseParamData(bytes memory _data) public pure returns (uint amount,address token,uint8 flType) {
        (amount, token, flType) = abi.decode(_data,(uint256,address,uint8));
    }

    function actionType() override public pure returns (uint8) {
        return uint8(ActionType.FL_ACTION);
    }

}