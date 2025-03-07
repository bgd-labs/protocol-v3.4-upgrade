// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IPool} from "aave-v3-origin/contracts/interfaces/IPool.sol";

import {AaveV3EthereumAssets} from "aave-address-book/AaveV3Ethereum.sol";

import {IGhoToken} from "gho-direct-minter/interfaces/IGhoToken.sol";

import {ATokenInstance} from "./ATokenInstance.sol";

import {IATokenMainnetInstanceGHO} from "./interfaces/IATokenMainnetInstanceGHO.sol";

contract ATokenMainnetInstanceGHO is ATokenInstance, IATokenMainnetInstanceGHO {
  // These are additional variables that were in the v3.3 AToken for the GHO aToken
  // but there is no such variables in all other aTokens in both v3.3 and v3.4
  // so we need to clean them in case in future versions of aTokens it will be
  // needed to add new storage variables.
  // If we don't clean them, then the aToken for the GHO token will have non zero values
  // in these new variables that may be added in the future.
  address private _deprecated_ghoVariableDebtToken;
  address private _deprecated_ghoTreasury;

  constructor(IPool pool, address rewardsController, address treasury)
    ATokenInstance(pool, rewardsController, treasury)
  {}

  /// @inheritdoc IATokenMainnetInstanceGHO
  function resolveFacilitator(uint256 amount) external override onlyPoolAdmin {
    delete _deprecated_ghoVariableDebtToken;
    delete _deprecated_ghoTreasury;

    IGhoToken(AaveV3EthereumAssets.GHO_UNDERLYING).burn(amount);
  }
}
