// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
  EthereumScript,
  PolygonScript,
  AvalancheScript,
  OptimismScript,
  ArbitrumScript,
  MetisScript,
  BaseScript,
  GnosisScript,
  ScrollScript,
  BNBScript,
  LineaScript
} from "solidity-utils/contracts/utils/ScriptUtils.sol";

import {GovV3Helpers} from "aave-helpers/src/GovV3Helpers.sol";

import {AaveProtocolDataProvider} from "aave-v3-origin/contracts/helpers/AaveProtocolDataProvider.sol";

import {PoolConfiguratorInstance} from "aave-v3-origin/contracts/instances/PoolConfiguratorInstance.sol";
import {ATokenInstance} from "aave-v3-origin/contracts/instances/ATokenInstance.sol";
import {VariableDebtTokenInstance} from "aave-v3-origin/contracts/instances/VariableDebtTokenInstance.sol";
import {ATokenWithDelegationInstance} from "aave-v3-origin/contracts/instances/ATokenWithDelegationInstance.sol";

import {IPool} from "aave-v3-origin/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol";
import {IReserveInterestRateStrategy} from "aave-v3-origin/contracts/interfaces/IReserveInterestRateStrategy.sol";
import {IAaveIncentivesController} from "aave-v3-origin/contracts/interfaces/IAaveIncentivesController.sol";

import {GhoDirectMinter} from "gho-direct-minter/GhoDirectMinter.sol";

import {AaveV3Polygon, AaveV3PolygonAssets} from "aave-address-book/AaveV3Polygon.sol";
import {AaveV3Avalanche, AaveV3AvalancheAssets} from "aave-address-book/AaveV3Avalanche.sol";
import {AaveV3Optimism, AaveV3OptimismAssets} from "aave-address-book/AaveV3Optimism.sol";
import {AaveV3Arbitrum, AaveV3ArbitrumAssets} from "aave-address-book/AaveV3Arbitrum.sol";
import {AaveV3Ethereum, AaveV3EthereumAssets} from "aave-address-book/AaveV3Ethereum.sol";
import {AaveV3BNB, AaveV3BNBAssets} from "aave-address-book/AaveV3BNB.sol";
import {AaveV3Gnosis, AaveV3GnosisAssets} from "aave-address-book/AaveV3Gnosis.sol";
import {AaveV3Scroll, AaveV3ScrollAssets} from "aave-address-book/AaveV3Scroll.sol";
import {AaveV3Base, AaveV3BaseAssets} from "aave-address-book/AaveV3Base.sol";
import {AaveV3Metis, AaveV3MetisAssets} from "aave-address-book/AaveV3Metis.sol";
import {AaveV3EthereumLido, AaveV3EthereumLidoAssets} from "aave-address-book/AaveV3EthereumLido.sol";
import {AaveV3EthereumEtherFi, AaveV3EthereumEtherFiAssets} from "aave-address-book/AaveV3EthereumEtherFi.sol";
import {AaveV3Linea, AaveV3LineaAssets} from "aave-address-book/AaveV3Linea.sol";

import {MiscEthereum} from "aave-address-book/MiscEthereum.sol";
import {GovernanceV3Ethereum} from "aave-address-book/GovernanceV3Ethereum.sol";

import {UpgradePayload, UpgradePayloadMainnet} from "../src/UpgradePayload.sol";
import {ATokenMainnetInstanceGHO} from "../src/ATokenMainnetInstanceGHO.sol";
import {VariableDebtTokenMainnetInstanceGHO} from "../src/VariableDebtTokenMainnetInstanceGHO.sol";
import {PoolInstanceWithCustomInitialize} from "../src/PoolInstanceWithCustomInitialize.sol";
import {L2PoolInstanceWithCustomInitialize} from "../src/L2PoolInstanceWithCustomInitialize.sol";

import {ITransparentProxyFactory} from
  "solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol";

library DeploymentLibrary {
  // rollups
  function _deployOptimism() internal returns (address) {
    DeployParameters memory deployParams;

    deployParams.pool = address(AaveV3Optimism.POOL);
    deployParams.poolAddressesProvider = address(AaveV3Optimism.POOL_ADDRESSES_PROVIDER);
    deployParams.interestRateStrategy = address(AaveV3OptimismAssets.WETH_INTEREST_RATE_STRATEGY);
    deployParams.rewardsController = AaveV3Optimism.DEFAULT_INCENTIVES_CONTROLLER;
    deployParams.treasury = address(AaveV3Optimism.COLLECTOR);

    return _deployL2(deployParams);
  }

  function _deployBase() internal returns (address) {
    DeployParameters memory deployParams;

    deployParams.pool = address(AaveV3Base.POOL);
    deployParams.poolAddressesProvider = address(AaveV3Base.POOL_ADDRESSES_PROVIDER);
    deployParams.interestRateStrategy = address(AaveV3BaseAssets.WETH_INTEREST_RATE_STRATEGY);
    deployParams.rewardsController = AaveV3Base.DEFAULT_INCENTIVES_CONTROLLER;
    deployParams.treasury = address(AaveV3Base.COLLECTOR);

    return _deployL2(deployParams);
  }

  function _deployArbitrum() internal returns (address) {
    DeployParameters memory deployParams;

    deployParams.pool = address(AaveV3Arbitrum.POOL);
    deployParams.poolAddressesProvider = address(AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER);
    deployParams.interestRateStrategy = address(AaveV3ArbitrumAssets.WETH_INTEREST_RATE_STRATEGY);
    deployParams.rewardsController = AaveV3Arbitrum.DEFAULT_INCENTIVES_CONTROLLER;
    deployParams.treasury = address(AaveV3Arbitrum.COLLECTOR);

    return _deployL2(deployParams);
  }

  function _deployScroll() internal returns (address) {
    DeployParameters memory deployParams;

    deployParams.pool = address(AaveV3Scroll.POOL);
    deployParams.poolAddressesProvider = address(AaveV3Scroll.POOL_ADDRESSES_PROVIDER);
    deployParams.interestRateStrategy = address(AaveV3ScrollAssets.WETH_INTEREST_RATE_STRATEGY);
    deployParams.rewardsController = AaveV3Scroll.DEFAULT_INCENTIVES_CONTROLLER;
    deployParams.treasury = address(AaveV3Scroll.COLLECTOR);

    return _deployL2(deployParams);
  }

  function _deployMetis() internal returns (address) {
    DeployParameters memory deployParams;

    deployParams.pool = address(AaveV3Metis.POOL);
    deployParams.poolAddressesProvider = address(AaveV3Metis.POOL_ADDRESSES_PROVIDER);
    deployParams.interestRateStrategy = address(AaveV3MetisAssets.WETH_INTEREST_RATE_STRATEGY);
    deployParams.rewardsController = AaveV3Metis.DEFAULT_INCENTIVES_CONTROLLER;
    deployParams.treasury = address(AaveV3Metis.COLLECTOR);

    return _deployL2(deployParams);
  }

  // L1s
  function _deployMainnet() internal returns (address) {
    DeployParameters memory deployParams;

    deployParams.pool = address(AaveV3Ethereum.POOL);
    deployParams.poolAddressesProvider = address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER);
    deployParams.interestRateStrategy = address(AaveV3EthereumAssets.WETH_INTEREST_RATE_STRATEGY);
    deployParams.rewardsController = AaveV3Ethereum.DEFAULT_INCENTIVES_CONTROLLER;
    deployParams.treasury = address(AaveV3Ethereum.COLLECTOR);

    return _deployL1(deployParams, true);
  }

  function _deployMainnetLido() internal returns (address) {
    DeployParameters memory deployParams;

    deployParams.pool = address(AaveV3EthereumLido.POOL);
    deployParams.poolAddressesProvider = address(AaveV3EthereumLido.POOL_ADDRESSES_PROVIDER);
    deployParams.interestRateStrategy = address(AaveV3EthereumLidoAssets.WETH_INTEREST_RATE_STRATEGY);
    deployParams.rewardsController = AaveV3EthereumLido.DEFAULT_INCENTIVES_CONTROLLER;
    deployParams.treasury = address(AaveV3EthereumLido.COLLECTOR);

    return _deployL1(deployParams, false);
  }

  function _deployMainnetEtherfi() internal returns (address) {
    DeployParameters memory deployParams;

    deployParams.pool = address(AaveV3EthereumEtherFi.POOL);
    deployParams.poolAddressesProvider = address(AaveV3EthereumEtherFi.POOL_ADDRESSES_PROVIDER);
    deployParams.interestRateStrategy = address(AaveV3EthereumEtherFiAssets.FRAX_INTEREST_RATE_STRATEGY);
    deployParams.rewardsController = AaveV3EthereumEtherFi.DEFAULT_INCENTIVES_CONTROLLER;
    deployParams.treasury = address(AaveV3EthereumEtherFi.COLLECTOR);

    return _deployL1(deployParams, false);
  }

  function _deployGnosis() internal returns (address) {
    DeployParameters memory deployParams;

    deployParams.pool = address(AaveV3Gnosis.POOL);
    deployParams.poolAddressesProvider = address(AaveV3Gnosis.POOL_ADDRESSES_PROVIDER);
    deployParams.interestRateStrategy = address(AaveV3GnosisAssets.WETH_INTEREST_RATE_STRATEGY);
    deployParams.rewardsController = AaveV3Gnosis.DEFAULT_INCENTIVES_CONTROLLER;
    deployParams.treasury = address(AaveV3Gnosis.COLLECTOR);

    return _deployL1(deployParams, false);
  }

  function _deployBNB() internal returns (address) {
    DeployParameters memory deployParams;

    deployParams.pool = address(AaveV3BNB.POOL);
    deployParams.poolAddressesProvider = address(AaveV3BNB.POOL_ADDRESSES_PROVIDER);
    deployParams.interestRateStrategy = address(AaveV3BNBAssets.ETH_INTEREST_RATE_STRATEGY);
    deployParams.rewardsController = AaveV3BNB.DEFAULT_INCENTIVES_CONTROLLER;
    deployParams.treasury = address(AaveV3BNB.COLLECTOR);

    return _deployL1(deployParams, false);
  }

  function _deployAvalanche() internal returns (address) {
    DeployParameters memory deployParams;

    deployParams.pool = address(AaveV3Avalanche.POOL);
    deployParams.poolAddressesProvider = address(AaveV3Avalanche.POOL_ADDRESSES_PROVIDER);
    deployParams.interestRateStrategy = address(AaveV3AvalancheAssets.WETHe_INTEREST_RATE_STRATEGY);
    deployParams.rewardsController = AaveV3Avalanche.DEFAULT_INCENTIVES_CONTROLLER;
    deployParams.treasury = address(AaveV3Avalanche.COLLECTOR);

    return _deployL1(deployParams, false);
  }

  function _deployPolygon() internal returns (address) {
    DeployParameters memory deployParams;

    deployParams.pool = address(AaveV3Polygon.POOL);
    deployParams.poolAddressesProvider = address(AaveV3Polygon.POOL_ADDRESSES_PROVIDER);
    deployParams.interestRateStrategy = address(AaveV3PolygonAssets.WETH_INTEREST_RATE_STRATEGY);
    deployParams.rewardsController = AaveV3Polygon.DEFAULT_INCENTIVES_CONTROLLER;
    deployParams.treasury = address(AaveV3Polygon.COLLECTOR);

    return _deployL1(deployParams, false);
  }

  function _deployLinea() internal returns (address) {
    DeployParameters memory deployParams;

    deployParams.pool = address(AaveV3Linea.POOL);
    deployParams.poolAddressesProvider = address(AaveV3Linea.POOL_ADDRESSES_PROVIDER);
    deployParams.interestRateStrategy = address(AaveV3LineaAssets.WETH_INTEREST_RATE_STRATEGY);
    deployParams.rewardsController = AaveV3Linea.DEFAULT_INCENTIVES_CONTROLLER;
    deployParams.treasury = address(AaveV3Linea.COLLECTOR);

    return _deployL1(deployParams, false);
  }

  struct DeployParameters {
    address poolAddressesProvider;
    address pool;
    address interestRateStrategy;
    address rewardsController;
    address treasury;
  }

  function _deployL2(DeployParameters memory deployParams) internal returns (address) {
    UpgradePayload.ConstructorParams memory payloadParams;

    payloadParams.poolAddressesProvider = IPoolAddressesProvider(deployParams.poolAddressesProvider);
    payloadParams.poolImpl = GovV3Helpers.deployDeterministic(
      type(L2PoolInstanceWithCustomInitialize).creationCode,
      abi.encode(deployParams.poolAddressesProvider, deployParams.interestRateStrategy)
    );

    return _deployPayload(deployParams, payloadParams, false);
  }

  function _deployL1(DeployParameters memory deployParams, bool isMainnetCore) internal returns (address) {
    UpgradePayload.ConstructorParams memory payloadParams;

    payloadParams.poolAddressesProvider = IPoolAddressesProvider(deployParams.poolAddressesProvider);
    payloadParams.poolImpl = GovV3Helpers.deployDeterministic(
      type(PoolInstanceWithCustomInitialize).creationCode, abi.encode(deployParams.poolAddressesProvider, deployParams.interestRateStrategy)
    );

    return _deployPayload(deployParams, payloadParams, isMainnetCore);
  }

  function _deployPayload(
    DeployParameters memory deployParams,
    UpgradePayload.ConstructorParams memory payloadParams,
    bool isMainnetCore
  ) private returns (address) {
    payloadParams.poolConfiguratorImpl = GovV3Helpers.deployDeterministic(type(PoolConfiguratorInstance).creationCode);

    payloadParams.poolDataProvider = GovV3Helpers.deployDeterministic(
      type(AaveProtocolDataProvider).creationCode, abi.encode(deployParams.poolAddressesProvider)
    );

    payloadParams.aTokenImpl = GovV3Helpers.deployDeterministic(
      type(ATokenInstance).creationCode,
      abi.encode(deployParams.pool, deployParams.rewardsController, deployParams.treasury)
    );

    payloadParams.vTokenImpl = GovV3Helpers.deployDeterministic(
      type(VariableDebtTokenInstance).creationCode, abi.encode(deployParams.pool, deployParams.rewardsController)
    );

    if (isMainnetCore) {
      return _deployMainnet(payloadParams);
    } else {
      return address(new UpgradePayload(payloadParams));
    }
  }

  function _deployMainnet(UpgradePayload.ConstructorParams memory params) internal returns (address) {
    // its the council used on other GHO stewards
    // might make sense to have on address book
    address council = 0x8513e6F37dBc52De87b166980Fa3F50639694B60;

    // Deploy a new GHO facilitator for the proto pool
    address ghoFacilitatorImpl = address(
      new GhoDirectMinter(
        AaveV3Ethereum.POOL_ADDRESSES_PROVIDER, address(AaveV3Ethereum.COLLECTOR), AaveV3EthereumAssets.GHO_UNDERLYING
      )
    );
    address ghoFacilitator = ITransparentProxyFactory(MiscEthereum.TRANSPARENT_PROXY_FACTORY).create(
      ghoFacilitatorImpl,
      MiscEthereum.PROXY_ADMIN,
      abi.encodeWithSelector(GhoDirectMinter.initialize.selector, GovernanceV3Ethereum.EXECUTOR_LVL_1, council)
    );

    ATokenMainnetInstanceGHO aTokenImplGho = new ATokenMainnetInstanceGHO(
      IPool(address(AaveV3Ethereum.POOL)),
      AaveV3Ethereum.DEFAULT_INCENTIVES_CONTROLLER,
      address(AaveV3Ethereum.COLLECTOR)
    );

    VariableDebtTokenMainnetInstanceGHO vTokenImplGho = new VariableDebtTokenMainnetInstanceGHO(
      IPool(address(AaveV3Ethereum.POOL)), AaveV3Ethereum.DEFAULT_INCENTIVES_CONTROLLER
    );

    ATokenWithDelegationInstance aTokenWithDelegationImpl = new ATokenWithDelegationInstance(
      IPool(address(AaveV3Ethereum.POOL)),
      AaveV3Ethereum.DEFAULT_INCENTIVES_CONTROLLER,
      address(AaveV3Ethereum.COLLECTOR)
    );

    return address(
      new UpgradePayloadMainnet(
        UpgradePayloadMainnet.ConstructorMainnetParams({
          poolAddressesProvider: IPoolAddressesProvider(address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER)),
          poolDataProvider: params.poolDataProvider,
          poolImpl: params.poolImpl,
          poolConfiguratorImpl: params.poolConfiguratorImpl,
          aTokenImpl: params.aTokenImpl,
          vTokenImpl: params.vTokenImpl,
          aTokenGhoImpl: address(aTokenImplGho),
          vTokenGhoImpl: address(vTokenImplGho),
          aTokenWithDelegationImpl: address(aTokenWithDelegationImpl),
          ghoFacilitator: ghoFacilitator
        })
      )
    );
  }
}

contract Deploypolygon is PolygonScript {
  function run() external broadcast {
    DeploymentLibrary._deployPolygon();
  }
}

contract Deploygnosis is GnosisScript {
  function run() external broadcast {
    DeploymentLibrary._deployGnosis();
  }
}

contract Deployoptimism is OptimismScript {
  function run() external broadcast {
    DeploymentLibrary._deployOptimism();
  }
}

contract Deployarbitrum is ArbitrumScript {
  function run() external broadcast {
    DeploymentLibrary._deployArbitrum();
  }
}

contract Deployavalanche is AvalancheScript {
  function run() external broadcast {
    DeploymentLibrary._deployAvalanche();
  }
}

contract Deploybase is BaseScript {
  function run() external broadcast {
    DeploymentLibrary._deployBase();
  }
}

contract Deployscroll is ScrollScript {
  function run() external broadcast {
    DeploymentLibrary._deployScroll();
  }
}

contract Deploybnb is BNBScript {
  function run() external broadcast {
    DeploymentLibrary._deployBNB();
  }
}

// metis is broken
contract Deploymetis is MetisScript {
  function run() external broadcast {
    DeploymentLibrary._deployMetis();
  }
}

contract Deploymainnet is EthereumScript {
  function run() external broadcast {
    DeploymentLibrary._deployMainnet();
  }
}

contract Deploylido is EthereumScript {
  function run() external broadcast {
    DeploymentLibrary._deployMainnetLido();
  }
}

contract Deployetherfi is EthereumScript {
  function run() external broadcast {
    DeploymentLibrary._deployMainnetEtherfi();
  }
}

contract Deploylinea is LineaScript {
  function run() external broadcast {
    DeploymentLibrary._deployLinea();
  }
}
