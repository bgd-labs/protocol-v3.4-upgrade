// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IAccessControl} from "openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IPool} from "aave-v3-origin/contracts/interfaces/IPool.sol";
import {IPoolConfigurator} from "aave-v3-origin/contracts/interfaces/IPoolConfigurator.sol";
import {IAToken} from "aave-v3-origin/contracts/interfaces/IAToken.sol";
import {IPoolAddressesProvider} from "aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol";
import {ConfiguratorInputTypes} from "aave-v3-origin/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol";

import {AaveV3Ethereum, AaveV3EthereumAssets} from "aave-address-book/AaveV3Ethereum.sol";
import {MiscEthereum} from "aave-address-book/MiscEthereum.sol";

import {IGhoDirectMinter} from "gho-direct-minter/interfaces/IGhoDirectMinter.sol";
import {IGhoToken} from "gho-direct-minter/interfaces/IGhoToken.sol";

import {IATokenMainnetInstanceGHO} from "./interfaces/IATokenMainnetInstanceGHO.sol";
import {IOldATokenMainnetInstanceGHO} from "./interfaces/IOldATokenMainnetInstanceGHO.sol";
import {IVariableDebtTokenMainnetInstanceGHO} from "./interfaces/IVariableDebtTokenMainnetInstanceGHO.sol";

/**
 * @title UpgradePayload
 * @notice Upgrade payload to upgrade the Aave v3.3 to v3.4
 * @author BGD Labs
 */
contract UpgradePayload {
  struct ConstructorParams {
    IPoolAddressesProvider poolAddressesProvider;
    address poolDataProvider;
    address poolImpl;
    address poolConfiguratorImpl;
    address aTokenImpl;
    address vTokenImpl;
  }

  IPoolAddressesProvider public immutable POOL_ADDRESSES_PROVIDER;
  address public immutable POOL_DATA_PROVIDER;
  IPool public immutable POOL;
  IPoolConfigurator public immutable POOL_CONFIGURATOR;

  address public immutable POOL_IMPL;
  address public immutable POOL_CONFIGURATOR_IMPL;
  address public immutable A_TOKEN_IMPL;
  address public immutable V_TOKEN_IMPL;

  constructor(ConstructorParams memory params) {
    POOL_ADDRESSES_PROVIDER = params.poolAddressesProvider;
    POOL_DATA_PROVIDER = params.poolDataProvider;

    POOL = IPool(params.poolAddressesProvider.getPool());
    POOL_CONFIGURATOR = IPoolConfigurator(params.poolAddressesProvider.getPoolConfigurator());

    POOL_IMPL = params.poolImpl;
    POOL_CONFIGURATOR_IMPL = params.poolConfiguratorImpl;
    A_TOKEN_IMPL = params.aTokenImpl;
    V_TOKEN_IMPL = params.vTokenImpl;
  }

  function execute() public virtual {
    // 1. Upgrade pool and configurator implementations
    // to be able to use v3.4 interfaces for the pool and configurator
    POOL_ADDRESSES_PROVIDER.setPoolImpl(POOL_IMPL);
    POOL_ADDRESSES_PROVIDER.setPoolConfiguratorImpl(POOL_CONFIGURATOR_IMPL);

    // 2. Set a new pool data provider
    POOL_ADDRESSES_PROVIDER.setPoolDataProvider(POOL_DATA_PROVIDER);

    // 3. Update aTokens and vTokens for all reserves
    address[] memory reserves = POOL.getReservesList();
    uint256 length = reserves.length;
    for (uint256 i = 0; i < length; i++) {
      address reserve = reserves[i];

      if (!_needToUpdateReserve(reserve)) {
        continue;
      }

      POOL_CONFIGURATOR.updateAToken(_prepareATokenUpdateInfo(reserve));

      POOL_CONFIGURATOR.updateVariableDebtToken(_prepareVTokenUpdateInfo(reserve));
    }
  }

  function _prepareATokenUpdateInfo(address underlyingToken)
    internal
    view
    returns (ConfiguratorInputTypes.UpdateATokenInput memory)
  {
    IERC20Metadata aToken = IERC20Metadata(POOL.getReserveAToken(underlyingToken));

    return ConfiguratorInputTypes.UpdateATokenInput({
      asset: underlyingToken,
      implementation: A_TOKEN_IMPL,
      params: "",
      name: aToken.name(),
      symbol: aToken.symbol()
    });
  }

  function _prepareVTokenUpdateInfo(address underlyingToken)
    internal
    view
    returns (ConfiguratorInputTypes.UpdateDebtTokenInput memory)
  {
    IERC20Metadata vToken = IERC20Metadata(POOL.getReserveVariableDebtToken(underlyingToken));

    return ConfiguratorInputTypes.UpdateDebtTokenInput({
      asset: underlyingToken,
      implementation: V_TOKEN_IMPL,
      params: "",
      name: vToken.name(),
      symbol: vToken.symbol()
    });
  }

  function _needToUpdateReserve(address) internal view virtual returns (bool) {
    return true;
  }
}

/**
 * @title UpgradePayloadMainnet
 * @notice Upgrade payload for the ETH Mainnet network to upgrade the Aave v3.3 to v3.4
 * @author BGD Labs
 */
contract UpgradePayloadMainnet is UpgradePayload {
  struct ConstructorMainnetParams {
    IPoolAddressesProvider poolAddressesProvider;
    address poolDataProvider;
    address poolImpl;
    address poolConfiguratorImpl;
    address aTokenImpl;
    address vTokenImpl;
    address aTokenGhoImpl;
    address vTokenGhoImpl;
    address ghoFacilitator;
  }

  address public immutable A_TOKEN_GHO_IMPL;
  address public immutable V_TOKEN_GHO_IMPL;

  address public immutable FACILITATOR;

  constructor(ConstructorMainnetParams memory params)
    UpgradePayload(
      ConstructorParams({
        poolAddressesProvider: params.poolAddressesProvider,
        poolDataProvider: params.poolDataProvider,
        poolImpl: params.poolImpl,
        poolConfiguratorImpl: params.poolConfiguratorImpl,
        aTokenImpl: params.aTokenImpl,
        vTokenImpl: params.vTokenImpl
      })
    )
  {
    A_TOKEN_GHO_IMPL = params.aTokenGhoImpl;
    V_TOKEN_GHO_IMPL = params.vTokenGhoImpl;

    FACILITATOR = params.ghoFacilitator;
  }

  function execute() public override {
    // 1. Give risk admin role to the new facilitator for accessing
    // the `setSupplyCap` function in the `PoolConfigurator` contract
    AaveV3Ethereum.ACL_MANAGER.addRiskAdmin(FACILITATOR);

    // 2. Initialize the new facilitator with levels of the previous facilitator
    (uint256 capacity, uint256 level) =
      IGhoToken(AaveV3EthereumAssets.GHO_UNDERLYING).getFacilitatorBucket(AaveV3EthereumAssets.GHO_A_TOKEN);
    IGhoToken(AaveV3EthereumAssets.GHO_UNDERLYING).addFacilitator(FACILITATOR, "GhoDirectMinter", uint128(capacity));

    // Right now there is the total supply of the `GHO_A_TOKEN` equals to zero
    // and also there is some GHO minted tokens by this aToken (variable `level`).
    //
    // We need to take into an account that there are some GHO tokens that the aToken contract
    // holds on its balance. Need to call the `distributeFeesToTreasury` function of the the old GHO aToken
    // to transfer this balance to the treasury. After this operation, the `GHO_A_TOKEN` will have
    // zero GHO balance.

    // 3. Transfer the current balance of the `GHO_A_TOKEN` to the treasury
    IOldATokenMainnetInstanceGHO(AaveV3EthereumAssets.GHO_A_TOKEN).distributeFeesToTreasury();

    // 4. Upgrade the POOL_CONFIGURATOR to the new version in order to be able to upgrade
    // the aToken (the initialize function for the v3.4 aToken is different from the v3.3)
    POOL_ADDRESSES_PROVIDER.setPoolConfiguratorImpl(POOL_CONFIGURATOR_IMPL);

    // 5. Upgrade the aToken of the GHO token to the new version in order to be able to
    // mint aTokens to the `GhoDirectMinter` contract
    POOL_CONFIGURATOR.updateAToken(
      ConfiguratorInputTypes.UpdateATokenInput({
        asset: AaveV3EthereumAssets.GHO_UNDERLYING,
        name: "Aave Ethereum GHO",
        symbol: "aEthGHO",
        implementation: A_TOKEN_GHO_IMPL,
        params: ""
      })
    );

    // 6. Mint and supply GHO to the pool
    // Need to do this before the v3.4 upgrade in order not to change the `virtualUnderlyingBalance` variable
    // in the Pool contract. Right now it equals to zero.
    IGhoDirectMinter(FACILITATOR).mintAndSupply(level);

    // 7. call the `resolveFacilitator` function on the aToken to burn the underlying GHO, in turn reducing level to 0
    IATokenMainnetInstanceGHO(AaveV3EthereumAssets.GHO_A_TOKEN).resolveFacilitator(level);

    // 8. remove the old facilitator
    IGhoToken(AaveV3EthereumAssets.GHO_UNDERLYING).removeFacilitator(AaveV3EthereumAssets.GHO_A_TOKEN);

    // 9. set reserve factor to 100% so all fee is accrued to treasury and index stays at 1
    POOL_CONFIGURATOR.setReserveFactor(AaveV3EthereumAssets.GHO_UNDERLYING, 100_00);

    // 10. set a supply cap so noone can supply, as 0 currently is unlimited
    POOL_CONFIGURATOR.setSupplyCap(AaveV3EthereumAssets.GHO_UNDERLYING, 1);

    // 11. Make the normal v3.4 upgrade
    super.execute();

    // 12. Upgrade the vToken of the GHO token to the new version
    POOL_CONFIGURATOR.updateVariableDebtToken(
      ConfiguratorInputTypes.UpdateDebtTokenInput({
        asset: AaveV3EthereumAssets.GHO_UNDERLYING,
        name: "Aave Ethereum Variable Debt GHO",
        symbol: "variableDebtEthGHO",
        implementation: V_TOKEN_GHO_IMPL,
        params: ""
      })
    );

    // 13. Migrate the vToken of the GHO token to the new version
    IVariableDebtTokenMainnetInstanceGHO(AaveV3EthereumAssets.GHO_V_TOKEN).migrateToV3_4();
  }

  function _needToUpdateReserve(address reserve) internal view virtual override returns (bool) {
    if (reserve == AaveV3EthereumAssets.GHO_UNDERLYING) {
      return false;
    }

    return true;
  }
}
