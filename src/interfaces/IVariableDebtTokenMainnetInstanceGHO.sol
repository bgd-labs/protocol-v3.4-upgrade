// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IVariableDebtTokenMainnetInstanceGHO {
  /**
   * @notice Migrates the GHO variable debt token to version 3.4.
   * @dev This function is designed to clean up deprecated storage variables as part of the
   *      migration process. It should only be called by the pool admin.
   *      It deletes the `_deprecated_ghoAToken`, `_deprecated_discountToken`, and
   *      `_deprecated_discountRateStrategy` storage variables to ensure compatibility
   *      with future variable debt token upgrades. The `_deprecated_ghoUserState` mapping
   *      cannot be deleted and must be considered in future upgrades.
   */
  function migrateToV3_4() external;

  /**
   * @notice Updates the discount percents of the users when a discount token transfer occurs
   * @dev To be executed before the token transfer happens
   * @param sender The address of sender
   * @param recipient The address of recipient
   * @param senderDiscountTokenBalance The sender discount token balance
   * @param recipientDiscountTokenBalance The recipient discount token balance
   * @param amount The amount of discount token being transferred
   */
  function updateDiscountDistribution(
    address sender,
    address recipient,
    uint256 senderDiscountTokenBalance,
    uint256 recipientDiscountTokenBalance,
    uint256 amount
  ) external;
}
