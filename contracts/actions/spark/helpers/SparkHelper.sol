// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./MainnetSparkAddresses.sol";

import "../../../interfaces/aaveV3/IL2PoolV3.sol";
import "../../../interfaces/aaveV3/IAaveProtocolDataProvider.sol";
import "../../../interfaces/aaveV3/IPoolAddressesProvider.sol";

/// @title Utility functions and data used in Spark actions
contract SparkHelper is MainnetSparkAddresses {
    
    uint16 public constant SPARK_REFERRAL_CODE = 0;

    uint256 public constant STABLE_ID = 1;
    uint256 public constant VARIABLE_ID = 2;
    
    
    /// @notice Returns the lending pool contract of the specified market
    function getLendingPool(address _market) internal view returns (IL2PoolV3) {
        return IL2PoolV3(IPoolAddressesProvider(_market).getPool());
    }

    /// @notice Fetch the data provider for the specified market
    function getDataProvider(address _market) internal view returns (IAaveProtocolDataProvider) {
        return
            IAaveProtocolDataProvider(
                IPoolAddressesProvider(_market).getPoolDataProvider()
            );
    }

    function boolToBytes(bool x) internal pure returns (bytes1 r) {
       return x ? bytes1(0x01) : bytes1(0x00);
    }

    function bytesToBool(bytes1 x) internal pure returns (bool r) {
        return x != bytes1(0x00);
    }
    
    function getWholeDebt(address _market, address _tokenAddr, uint _borrowType, address _debtOwner) internal view returns (uint256 debt) {
        IAaveProtocolDataProvider dataProvider = getDataProvider(_market);
        (, uint256 borrowsStable, uint256 borrowsVariable, , , , , , ) =
            dataProvider.getUserReserveData(_tokenAddr, _debtOwner);

        if (_borrowType == STABLE_ID) {
            debt = borrowsStable;
        } else if (_borrowType == VARIABLE_ID) {
            debt = borrowsVariable;
        }
    }
}