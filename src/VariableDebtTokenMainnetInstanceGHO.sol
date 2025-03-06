// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {VariableDebtTokenInstance} from "aave-v3-origin/contracts/instances/VariableDebtTokenInstance.sol";
import {IPool} from "aave-v3-origin/contracts/interfaces/IPool.sol";

import {IVariableDebtTokenMainnetInstanceGHO} from "./interfaces/IVariableDebtTokenMainnetInstanceGHO.sol";

contract VariableDebtTokenMainnetInstanceGHO is VariableDebtTokenInstance, IVariableDebtTokenMainnetInstanceGHO {
  // These are additional variables that were in the v3.3 VToken for the GHO aToken
  // but there is no such variables in all other vTokens in both v3.3 and v3.4
  // so we need to clean them in case in future versions of vTokens it will be
  // needed to add new storage variables.
  // If we don't clean them, then the aToken for the GHO token will have non zero values
  // in these new variables that may be added in the future.
  address internal _deprecated_ghoAToken;
  address internal _deprecated_discountToken;
  address internal _deprecated_discountRateStrategy;

  // This global variable can't be cleaned. The future vToken code upgrades should consider
  // that on this slot there can't be a new mapping because it holds some non-zero values
  // On this slot there can be only value types, not reference types.
  // mapping(address => GhoUserState) internal _deprecated_ghoUserState;

  constructor(IPool pool, address rewardsController) VariableDebtTokenInstance(pool, rewardsController) {}

  /// @inheritdoc IVariableDebtTokenMainnetInstanceGHO
  function migrateToV3_4() external override onlyPoolAdmin {
    delete _deprecated_ghoAToken;
    delete _deprecated_discountToken;
    delete _deprecated_discountRateStrategy;
  }

  /// @inheritdoc IVariableDebtTokenMainnetInstanceGHO
  function updateDiscountDistribution(address, address, uint256, uint256, uint256) external override {}
}
