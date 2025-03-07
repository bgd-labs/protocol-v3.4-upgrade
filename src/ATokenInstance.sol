// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
  AToken,
  IPool,
  IAaveIncentivesController,
  IInitializableAToken,
  Errors,
  VersionedInitializable
} from "aave-v3-origin/contracts/protocol/tokenization/AToken.sol";

contract ATokenInstance is AToken {
  uint256 public constant ATOKEN_REVISION = 2;

  constructor(IPool pool, address rewardsController, address treasury) AToken(pool, rewardsController, treasury) {}

  /// @inheritdoc VersionedInitializable
  function getRevision() internal pure virtual override returns (uint256) {
    return ATOKEN_REVISION;
  }

  /// @inheritdoc IInitializableAToken
  function initialize(
    IPool initializingPool,
    address underlyingAsset,
    uint8 aTokenDecimals,
    string calldata aTokenName,
    string calldata aTokenSymbol,
    bytes calldata params
  ) public virtual override initializer {
    require(initializingPool == POOL, Errors.PoolAddressesDoNotMatch());
    _setName(aTokenName);
    _setSymbol(aTokenSymbol);
    _setDecimals(aTokenDecimals);

    _underlyingAsset = underlyingAsset;

    _domainSeparator = _calculateDomainSeparator();

    emit Initialized(
      underlyingAsset,
      address(POOL),
      address(TREASURY),
      address(REWARDS_CONTROLLER),
      aTokenDecimals,
      aTokenName,
      aTokenSymbol,
      params
    );
  }
}
