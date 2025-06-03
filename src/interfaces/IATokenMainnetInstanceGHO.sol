// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IATokenMainnetInstanceGHO {
  /**
   * @notice Resolves the facilitator by burning the specified amount of underlying GHO tokens.
   * @dev This function can be called only once because `UpgradePayload` will remove
   *      this contract as a facilitator from the GHO token.
   * @param amount The amount of underlying GHO tokens to burn.
   */
  function resolveFacilitator(uint256 amount) external;

  /**
   * @notice Handles the transfer of underlying assets (GHO) to the Treasury when a reserve deficit is covered.
   * @dev This function is specifically invoked by the Pool during the `executeEliminateDeficit` process
   * (see Aave v3.3 Pool's [`LiquidationLogic.sol#L141-L157`](https://github.com/bgd-labs/aave-v3-origin/blob/496c6eaf9056a25729a28c9e98b7757f975dc54a/src/contracts/protocol/libraries/logic/LiquidationLogic.sol#L141-L157))
   * for reserves like GHO where virtual accounting was disabled in v3.3.
   * When the Umbrella contract (or other authorized entity) covers a GHO deficit, it transfers GHO to this aToken contract.
   * The Pool then immediately calls this `handleRepayment` function on this aToken contract.
   * The primary action of this function is to forward these received GHO tokens from this aToken contract
   * to the Aave Treasury.
   * The `user` and `onBehalfOf` parameters are part of the IAToken interface for repayment functions.
   * In this specific deficit coverage flow originating from `executeEliminateDeficit`:
   * - `user` (first parameter) is the address that called `executeEliminateDeficit` on the Pool (e.g., the Umbrella contract).
   * - `onBehalfOf` (second parameter) is the Pool contract itself, which mediates the call to this `handleRepayment`.
   * @param user The address that initiated the deficit coverage on the Pool (e.g., Umbrella contract).
   * @param onBehalfOf The address for whom the repayment is made (in this flow, the Pool contract).
   * @param amount The amount of underlying GHO to be transferred from this contract to the Treasury.
   */
  function handleRepayment(address user, address onBehalfOf, uint256 amount) external;
}
