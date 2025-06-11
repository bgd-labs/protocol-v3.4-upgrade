// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ZkSyncScript} from "solidity-utils/contracts/utils/ScriptUtils.sol";
import {AaveProtocolDataProvider} from "aave-v3-origin/contracts/helpers/AaveProtocolDataProvider.sol";
import {PoolConfiguratorInstance} from "aave-v3-origin/contracts/instances/PoolConfiguratorInstance.sol";
import {ATokenInstance} from "aave-v3-origin/contracts/instances/ATokenInstance.sol";
import {VariableDebtTokenInstance} from "aave-v3-origin/contracts/instances/VariableDebtTokenInstance.sol";
import {IPoolAddressesProvider} from "aave-address-book/AaveV3.sol";
import {AaveV3ZkSync, AaveV3ZkSyncAssets} from "aave-address-book/AaveV3ZkSync.sol";
import {GovernanceV3ZkSync} from "aave-address-book/GovernanceV3ZkSync.sol";

import {UpgradePayload} from "../../src/UpgradePayload.sol";
import {PoolInstanceWithCustomInitialize} from "../../src/PoolInstanceWithCustomInitialize.sol";
import {PoolConfiguratorWithCustomInitialize} from "../../src/PoolConfiguratorWithCustomInitialize.sol";

library DeploymentLibrary {
  struct DeployParameters {
    address poolAddressesProvider;
    address pool;
    address interestRateStrategy;
    address rewardsController;
    address treasury;
  }

  function _deployZKSync() internal returns (address) {
    DeployParameters memory deployParams;

    deployParams.pool = address(AaveV3ZkSync.POOL);
    deployParams.poolAddressesProvider = address(AaveV3ZkSync.POOL_ADDRESSES_PROVIDER);
    deployParams.interestRateStrategy = address(AaveV3ZkSyncAssets.WETH_INTEREST_RATE_STRATEGY);
    deployParams.rewardsController = AaveV3ZkSync.DEFAULT_INCENTIVES_CONTROLLER;
    deployParams.treasury = address(AaveV3ZkSync.COLLECTOR);

    return _deployL1(params);
  }

  function _deployL1(UpgradePayload.ConstructorParams memory params) internal returns (address) {
    UpgradePayload.ConstructorParams memory payloadParams;

    payloadParams.poolAddressesProvider = IPoolAddressesProvider(deployParams.poolAddressesProvider);
    params.poolImpl = address(
      new PoolInstanceWithCustomInitialize{salt: "v1"}(
        deployParams.poolAddressesProvider, deployParams.interestRateStrategy
      )
    );
    return _deployPayload({deployParams: deployParams, payloadParams: payloadParams});
  }

  function _deployPayload(DeployParameters memory deployParams, UpgradePayload.ConstructorParams memory payloadParams)
    private
    returns (address)
  {
    params.poolConfiguratorImpl = address(new PoolConfiguratorWithCustomInitialize{salt: "v1"}());
    params.poolDataProvider = address(new AaveProtocolDataProvider{salt: "v1"}(deployParams.poolAddressesProvider));
    params.aTokenImpl =
      address(new ATokenInstance{salt: "v1"}(deployParams.pool, deployParams.rewardsController, deployParams.treasury));
    payloadParams.vTokenImpl =
      address(new VariableDebtTokenInstance{salt: "v1"}(deployParams.pool, deployParams.rewardsController));

    return address(new UpgradePayload(payloadParams));
  }
}

contract Deployzksync is ZkSyncScript {
  function run() external broadcast {
    DeploymentLibrary._deployZKSync();
  }
}

contract DeployGatewayzksync is ZkSyncScript {
  function run() external broadcast {
    new WrappedTokenGatewayV3(AaveV3ZkSyncAssets.WETH_UNDERLYING, GovernanceV3ZkSync.EXECUTOR_LVL_1, AaveV3ZkSync.POOL);
  }
}
