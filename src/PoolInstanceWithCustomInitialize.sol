// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {PoolInstance} from "aave-v3-origin/contracts/instances/PoolInstance.sol";
import {Errors} from "aave-v3-origin/contracts/protocol/libraries/helpers/Errors.sol";
import {IVariableDebtToken} from "aave-v3-origin/contracts/interfaces/IVariableDebtToken.sol";
import {IPoolAddressesProvider} from "aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol";
import {IReserveInterestRateStrategy} from "aave-v3-origin/contracts/interfaces/IReserveInterestRateStrategy.sol";
import {DataTypes} from "aave-v3-origin/contracts/protocol/pool/Pool.sol";
import {ReserveConfiguration} from "aave-v3-origin/contracts/protocol/libraries/configuration/ReserveConfiguration.sol";
import {WadRayMath} from "aave-v3-origin/contracts/protocol/libraries/math/WadRayMath.sol";
import {ReserveLogic} from "aave-v3-origin/contracts/protocol/libraries/logic/ReserveLogic.sol";

import {AaveV3EthereumAssets, AaveV3Ethereum} from "aave-address-book/AaveV3Ethereum.sol";

import {IGhoToken} from "gho-direct-minter/interfaces/IGhoToken.sol";

import {CustomInitialize} from "./CustomInitialize.sol";

contract PoolInstanceWithCustomInitialize is PoolInstance {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;
  using ReserveLogic for DataTypes.ReserveData;

  constructor(IPoolAddressesProvider provider, IReserveInterestRateStrategy interestRateStrategy_)
    PoolInstance(provider, interestRateStrategy_)
  {}

  /// @inheritdoc PoolInstance
  function initialize(IPoolAddressesProvider provider) external virtual override initializer {
    require(provider == ADDRESSES_PROVIDER, Errors.InvalidAddressesProvider());

    CustomInitialize._initialize(_reservesCount, _reservesList, _reserves);

    // @note Should be executed only on the Ethereum Mainnet Core Pool instance
    //       The check is sufficient as the Ethereum Core Pool address is unique across chains.
    if (address(this) == address(AaveV3Ethereum.POOL)) {
      // 1. Update the `virtualAcc` configuration of the GHO reserve

      DataTypes.ReserveData storage currentGHOConfig = _reserves[AaveV3EthereumAssets.GHO_UNDERLYING];
      DataTypes.ReserveConfigurationMap memory currentGHOConfigConfig = currentGHOConfig.configuration;

      currentGHOConfigConfig.setVirtualAccActive();

      currentGHOConfig.configuration = currentGHOConfigConfig;

      // 2. Update the `accruedToTreasury` variable of the GHO token

      uint256 normalizedDebt = _reserves[AaveV3EthereumAssets.GHO_UNDERLYING].getNormalizedDebt();
      uint256 vTokenScaledTotalSupply =
        IVariableDebtToken(currentGHOConfig.variableDebtTokenAddress).scaledTotalSupply();
      uint256 vTokenTotalSupply = vTokenScaledTotalSupply.rayMul(vTokenScaledTotalSupply);

      ( /* uint256 capacity */ , uint256 level) =
        IGhoToken(AaveV3EthereumAssets.GHO_UNDERLYING).getFacilitatorBucket(AaveV3EthereumAssets.GHO_A_TOKEN);

      currentGHOConfig.accruedToTreasury = uint128((vTokenTotalSupply - level).rayDiv(normalizedDebt));
    }
  }
}
