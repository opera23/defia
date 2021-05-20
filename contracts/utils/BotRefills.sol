// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "../auth/AdminAuth.sol";
import "../interfaces/exchange/IUniswapRouter.sol";
import "../interfaces/IBotRegistry.sol";
import "./TokenUtils.sol";

/// @title Contract used to refill tx sending bots when they are low on eth
contract BotRefills is AdminAuth {

    using TokenUtils for address;

    address internal refillCaller = 0x33fDb79aFB4456B604f376A45A546e7ae700e880;
    address internal feeAddr = 0x76720aC2574631530eC8163e4085d6F98513fb27;

    address internal constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;
    address internal constant DAI_ADDR = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    IUniswapRouter internal router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function refill(uint _ethAmount, address _botAddress) public  {
        require(msg.sender == refillCaller, "Wrong refill caller");
        require(IBotRegistry(BOT_REGISTRY_ADDRESS).botList(_botAddress), "Not auth bot");

        // check if we have enough weth to send
        uint wethBalance = IERC20(TokenUtils.WETH_ADDR).balanceOf(feeAddr);

        if (wethBalance >= _ethAmount) {
            IERC20(TokenUtils.WETH_ADDR).transferFrom(feeAddr, address(this), _ethAmount);

            TokenUtils.withdrawWeth(_ethAmount);
            payable(_botAddress).transfer(_ethAmount);
        } else {
            address[] memory path = new address[](2);
            path[0] = DAI_ADDR;
            path[1] = TokenUtils.WETH_ADDR;

            // get how much dai we need to convert
            uint daiAmount = getEth2Dai(_ethAmount);

            IERC20(DAI_ADDR).transferFrom(feeAddr, address(this), daiAmount);
            DAI_ADDR.approveToken(address(router), daiAmount);

            // swap and transfer directly to botAddress
            router.swapExactTokensForETH(daiAmount, 1, path, _botAddress, block.timestamp + 1);
        }
    }

    /// @dev Returns Dai amount, given eth amount based on uniV2 pool price
    function getEth2Dai(uint _ethAmount) internal view returns (uint daiAmount) {
        address[] memory path = new address[](2);
        path[0] = TokenUtils.WETH_ADDR;
        path[1] = DAI_ADDR;

        daiAmount = router.getAmountsOut(_ethAmount, path)[1];
    }

    function setRefillCaller(address _newBot) public onlyOwner {
        refillCaller = _newBot;
    }

    function setFeeAddr(address _newFeeAddr) public onlyOwner {
        feeAddr = _newFeeAddr;
    }

    receive() external payable {}
}