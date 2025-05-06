// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {PoolInstance} from "aave-v3-origin/contracts/instances/PoolInstance.sol";
import {Errors} from "aave-v3-origin/contracts/protocol/libraries/helpers/Errors.sol";
import {IPoolAddressesProvider} from "aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol";
import {IReserveInterestRateStrategy} from "aave-v3-origin/contracts/interfaces/IReserveInterestRateStrategy.sol";
import {DataTypes} from "aave-v3-origin/contracts/protocol/pool/Pool.sol";
import {ReserveConfiguration} from "aave-v3-origin/contracts/protocol/libraries/configuration/ReserveConfiguration.sol";
import {AaveV3EthereumAssets, AaveV3Ethereum} from "aave-address-book/AaveV3Ethereum.sol";

import {CustomInitialize} from "./CustomInitialize.sol";

contract PoolInstanceWithCustomInitialize is PoolInstance {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  constructor(IPoolAddressesProvider provider, IReserveInterestRateStrategy interestRateStrategy_)
    PoolInstance(provider, interestRateStrategy_)
  {}

  /// @inheritdoc PoolInstance
  function initialize(IPoolAddressesProvider provider) external virtual override initializer {
    require(provider == ADDRESSES_PROVIDER, Errors.InvalidAddressesProvider());

    CustomInitialize._initialize(_reservesCount, _reservesList, _reserves);

    // @note Should be executed only on the Ethereum Mainnet Core Pool instance
    if (address(this) == address(AaveV3Ethereum.POOL)) {
      DataTypes.ReserveData storage currentGHOConfig = _reserves[AaveV3EthereumAssets.GHO_UNDERLYING];
      DataTypes.ReserveConfigurationMap memory currentGHOConfigConfig = currentGHOConfig.configuration;

      currentGHOConfigConfig.setVirtualAccActive();

      currentGHOConfig.configuration = currentGHOConfigConfig;
    }
  }
}
