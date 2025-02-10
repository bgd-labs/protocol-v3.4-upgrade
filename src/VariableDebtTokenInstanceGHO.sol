// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
  VariableDebtToken,
  IPool,
  IInitializableDebtToken,
  VersionedInitializable,
  IAaveIncentivesController,
  Errors
} from "aave-v3-origin/contracts/protocol/tokenization/VariableDebtToken.sol";

/**
 * Modifications:
 * - bumped revision
 * - added noop updateDiscountDistribution function for backwards compatibility with stkAAVE
 */
contract VariableDebtTokenInstanceGHO is VariableDebtToken {
  uint256 public constant DEBT_TOKEN_REVISION = 4;

  constructor(IPool pool, address rewardsController) VariableDebtToken(pool, rewardsController) {}

  /// @inheritdoc VersionedInitializable
  function getRevision() internal pure virtual override returns (uint256) {
    return DEBT_TOKEN_REVISION;
  }

  /// @inheritdoc IInitializableDebtToken
  function initialize(
    IPool initializingPool,
    address underlyingAsset,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol,
    bytes calldata params
  ) external override initializer {
    require(initializingPool == POOL, Errors.PoolAddressesDoNotMatch());
    _setName(debtTokenName);
    _setSymbol(debtTokenSymbol);
    _setDecimals(debtTokenDecimals);

    _underlyingAsset = underlyingAsset;

    _domainSeparator = _calculateDomainSeparator();

    emit Initialized(
      underlyingAsset,
      address(POOL),
      address(REWARDS_CONTROLLER),
      debtTokenDecimals,
      debtTokenName,
      debtTokenSymbol,
      params
    );
  }

  // noop for backwards compatibility with the existing version of stkAAVE
  function updateDiscountDistribution(
    address sender,
    address recipient,
    uint256 senderDiscountTokenBalance,
    uint256 recipientDiscountTokenBalance,
    uint256 amount
  ) external {}
}
