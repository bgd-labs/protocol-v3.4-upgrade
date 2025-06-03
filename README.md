# Aave V3.4 Upgrade Process

This document outlines the technical process for upgrading the Aave V3 protocol from version 3.3 to version 3.4 across various networks.

The upgrade is executed via specialized `UpgradePayload` contracts deployed on each network. A specific version, `UpgradePayloadMainnet`, handles additional steps required for the Ethereum Mainnet due to the GHO token migration.

## Core Components of the Upgrade

1.  **New Implementations:** New implementations for the `Pool`, `PoolConfigurator`, `AToken`, `VariableDebtToken`, and `PoolDataProvider` contracts are deployed. These incorporate the v3.4 features and optimizations.
2.  **Custom Initializers:** Special logic (`CustomInitialize.sol`) is embedded within the new `Pool` implementations (`PoolInstanceWithCustomInitialize`, `L2PoolInstanceWithCustomInitialize`, `MainnetCorePoolInstanceWithCustomInitialize`) to handle storage slot migrations during the upgrade. A custom `PoolConfigurator` (`PoolConfiguratorWithCustomInitialize`) is used to capture state before the main pool upgrade.
3.  **GHO Specific Contracts (Mainnet):** Custom implementations for `aGHO` (`ATokenMainnetInstanceGHO`) and `vGHO` (`VariableDebtTokenMainnetInstanceGHO`) are used during the Mainnet upgrade to facilitate the GHO facilitator migration and clean up deprecated storage slots. A new `GhoDirectMinter` contract is deployed to take over GHO facilitation from the old `aGHO`.
4.  **Upgrade Payloads:** `UpgradePayload` (for most networks) and `UpgradePayloadMainnet` (for Ethereum Mainnet) contain the sequenced steps to orchestrate the upgrade.
5.  **Deployment Scripts:** Forge scripts (`Deploy.s.sol`) are used to deterministically deploy all necessary new implementation contracts and the corresponding upgrade payload contract for each network.

## Key Migration and Initialization Steps

Several changes in v3.4 require specific actions during the upgrade process:

1.  **Storage Slot Migration (`virtualUnderlyingBalance`):**

    - In v3.3, reserves had an `unbacked` storage slot that was unused. In v3.4, this feature is removed.
    - The `virtualUnderlyingBalance` slot (previously `__deprecatedVirtualUnderlyingBalance`) is moved into the storage slot formerly occupied by `unbacked` for gas optimization.
    - **Action:** The `initialize` function within the new `Pool` implementations (`PoolInstanceWithCustomInitialize`, `L2PoolInstanceWithCustomInitialize`), using the `CustomInitialize._initialize` library function, iterates through all reserves upon the first initialization after the upgrade. It copies the value from the old `__deprecatedVirtualUnderlyingBalance` slot to the new `virtualUnderlyingBalance` slot and zeroes out the old slot.

2.  **Flash Loan Premium Capture:**

    - The `FLASHLOAN_PREMIUM_TO_PROTOCOL` becomes a constant (`100_00`) in the v3.4 `Pool` implementation.
    - **Action:** The `PoolConfiguratorWithCustomInitialize` implementation, which is set _before_ the Pool is upgraded, reads the _old_ dynamic value from the v3.3 `Pool` via `_pool.FLASHLOAN_PREMIUM_TO_PROTOCOL()` during its `initialize` function. It emits an event (`FlashloanPremiumToProtocolUpdated`) if this value differs from the new constant value. This ensures the old value is recorded before it becomes inaccessible.

3.  **Deprecated Storage Cleanup (GHO Tokens on Mainnet):**
    - The v3.3 `aGHO` and `vGHO` contracts contained specific storage variables (`ghoVariableDebtToken`, `ghoTreasury` in aToken; `ghoAToken`, `discountToken`, `discountRateStrategy` in vToken) that are not present in standard tokens or the v3.4 GHO tokens.
    - **Action:**
      - The custom `ATokenMainnetInstanceGHO` implementation's `resolveFacilitator` function (called during the GHO migration) explicitly deletes the deprecated aToken storage slots.
      - The custom `VariableDebtTokenMainnetInstanceGHO` implementation's `initialize` function explicitly deletes the deprecated vToken storage slots.
      - This cleanup prevents potential storage collisions if future Aave versions add new variables at these storage slots for standard tokens.

## General Upgrade Sequence (via `UpgradePayload`)

This sequence applies to most networks (Polygon, Optimism, Arbitrum, etc.).

1.  **Upgrade PoolConfigurator Implementation:** The `PoolConfigurator` contract is updated to the new `PoolConfiguratorWithCustomInitialize` implementation. This is done first to ensure compatibility with v3.4 interfaces and the logic needed for subsequent steps (like token updates). The `initialize` function of this new configurator captures the old flash loan premium.
2.  **Upgrade Pool Implementation:** The `Pool` contract is updated to the new `PoolInstanceWithCustomInitialize` implementation (or `L2PoolInstanceWithCustomInitialize` on L2 networks, or `MainnetCorePoolInstanceWithCustomInitialize` for Mainnet Core). The `initialize` function of this new pool handles the `virtualUnderlyingBalance` storage migration.
3.  **Set New PoolDataProvider:** The `PoolAddressesProvider` is updated to point to the new `AaveProtocolDataProvider` implementation.
4.  **Update AToken/VariableDebtToken Implementations:** The payload iterates through all reserves listed in the `Pool`:
    - For each reserve, it calls `POOL_CONFIGURATOR.updateAToken` to upgrade the reserve's AToken proxy to the new standard `ATokenInstance` implementation (`A_TOKEN_IMPL`).
    - It then calls `POOL_CONFIGURATOR.updateVariableDebtToken` to upgrade the reserve's VariableDebtToken proxy to the new standard `VariableDebtTokenInstance` implementation (`V_TOKEN_IMPL`).

## Ethereum Mainnet Upgrade Sequence (via `UpgradePayloadMainnet`)

This sequence includes the general steps plus specific GHO migration steps, executed in a precise order after the `UpgradePayloadMainnet` contract is deployed.

**Pre-Execution Step (Payload Constructor):**

- **Deploy and Initialize New Facilitator:** The new `GhoDirectMinter` proxy contract (`FACILITATOR`) is deployed and initialized using the `TransparentProxyFactory` within the `constructor` of the `UpgradePayloadMainnet` contract. Its implementation, admin, owner (Executor LVL 1), and council are set during this deployment process.

**Execution Steps (Inside `execute()` function):**

1.  **Grant Facilitator Risk Admin:** The `ACL_MANAGER` grants the `RISK_ADMIN` role to the `GhoDirectMinter` contract (`FACILITATOR`). This allows `FACILITATOR` to call `setSupplyCap` on the `PoolConfigurator`.
2.  **Add New Facilitator to GhoToken:**
    - The current GHO bucket capacity and level of the old `aGHO` facilitator are fetched from the `GhoToken`.
    - The new `GhoDirectMinter` (`FACILITATOR`) is added as a GHO facilitator to the `GhoToken` contract (`IGhoToken(...).addFacilitator(...)`) using the fetched capacity.
3.  **Distribute Old aGHO Fees:** `IOldATokenMainnetInstanceGHO(AaveV3EthereumAssets.GHO_A_TOKEN).distributeFeesToTreasury()` is called to send any accumulated GHO fees in the old aToken contract to the treasury. This is a required step to make the balance of the `GHO_A_TOKEN` equal to zero.
4.  **Upgrade PoolConfigurator Implementation:** The `PoolConfigurator` contract is updated to the new `PoolConfiguratorWithCustomInitialize` implementation.
5.  **Upgrade aGHO to Custom Intermediate Implementation:** `POOL_CONFIGURATOR.updateAToken` is called for the GHO asset, setting its implementation to the custom `ATokenMainnetInstanceGHO` (`A_TOKEN_GHO_IMPL`). Its `initialize` function cleans its specific deprecated storage slots.
6.  **Mint and Supply by New Facilitator:** The `mintAndSupply` function of the new `GhoDirectMinter` (`FACILITATOR`) is called, minting GHO equal to the old `aGHO` facilitator's `levelFromOldFacilitator` and supplying it to the (still v3.3 logic) Aave pool, receiving `aGHO` tokens in return. This effectively pre-funds the aToken with GHO.
7.  **Resolve Old Facilitator:** `IATokenMainnetInstanceGHO(AaveV3EthereumAssets.GHO_A_TOKEN).resolveFacilitator(levelFromOldFacilitator)` is called. This function on the _custom_ `aGHO` implementation burns the underlying GHO token amount equal to `levelFromOldFacilitator` from the aToken's own balance. This burn offsets the GHO minted by the `FACILITATOR` in the previous step from the perspective of GHO total supply managed by `GhoToken`, and sets the old `aGHO` facilitator's bucket level to 0 in the `GhoToken`.
8.  **Remove Old Facilitator:** `IGhoToken(AaveV3EthereumAssets.GHO_UNDERLYING).removeFacilitator(AaveV3EthereumAssets.GHO_A_TOKEN)` is called. Since its level in `GhoToken` is now 0, the old `aGHO` contract is successfully removed as a facilitator.
9.  **Set GHO Reserve Factor:** `POOL_CONFIGURATOR.setReserveFactor` sets GHO's reserve factor to 100% (`100_00`).
10. **Set GHO Supply Cap:** `POOL_CONFIGURATOR.setSupplyCap` sets GHO's supply cap to 1 wei, effectively preventing user GHO deposits.
11. **Reset UNI AToken Delegation (If Active):** Checks if the UNI AToken (`AaveV3EthereumAssets.UNI_A_TOKEN`) has delegated its underlying UNI voting power. If so, the delegation is reset to `address(0)` by calling `delegateUnderlyingTo(address(0))` on the UNI AToken. This action requires the payload (caller) to have the "Pool Admin" role.
12. **Clear Existing GHO Deficit (v3.3 Mechanism):**
    * **Context:** Before upgrading the main `Pool` contract to its v3.4 implementation (which enables virtual accounting for GHO as a standard feature), any existing GHO deficit under the v3.3 rules must be cleared. In v3.3, GHO had virtual accounting disabled.
    * **Process:**
        1.  The current GHO deficit is fetched from the v3.3 `Pool` (`AaveV3Ethereum.POOL.getReserveDeficit(...)`).
        2.  If a deficit exists:
            * The Aave Collector contract (`AaveV3Ethereum.COLLECTOR`) transfers the deficit amount of GHO tokens to the `UpgradePayloadMainnet` contract.
            * The `UpgradePayloadMainnet` contract then approves the `UmbrellaEthereum.UMBRELLA` contract to spend these GHO tokens.
            * `UmbrellaEthereum.UMBRELLA.coverDeficitOffset()` is called for the GHO asset. This function call triggers the v3.3 `Pool`'s `executeEliminateDeficit` function.
            * For GHO (as virtual accounting was disabled in v3.3), the `executeEliminateDeficit` logic involves:
                * The Pool contract transfers the GHO to the `GHO_A_TOKEN` contract.
                * The Pool then calling `handleRepayment(UmbrellaAddress, PoolAddress, deficitAmount)` on the `GHO_A_TOKEN` contract.
                * The `ATokenMainnetInstanceGHO.handleRepayment()` function (which is the current implementation for `aGHO`) then transfers these GHO tokens from the `GHO_A_TOKEN` contract to the `TREASURY`.
13. **Execute Default Upgrade Steps:** The `_defaultUpgrade()` function is called. This:
    * Upgrades the `Pool` implementation to `MainnetCorePoolInstanceWithCustomInitialize` (`POOL_IMPL`). The `initialize` function of this new pool:
        * Runs `CustomInitialize._initialize` for general storage migrations (e.g., `virtualUnderlyingBalance`).
        * Specifically for GHO: sets `virtualAccActive` to true in its configuration and calculates and sets `accruedToTreasury`.
    * Sets the new `PoolDataProvider` (`POOL_DATA_PROVIDER`).
    * Updates standard AToken (`A_TOKEN_IMPL`) and VariableDebtToken (`V_TOKEN_IMPL`) implementations for all other reserves (GHO and AAVE are skipped here as per `_needToUpdateReserve` and handled by specific steps).
14. **Upgrade vGHO to Custom Implementation:** `POOL_CONFIGURATOR.updateVariableDebtToken` is called for GHO, setting its implementation to the custom `VariableDebtTokenMainnetInstanceGHO` (`V_TOKEN_GHO_IMPL`). Its `initialize` function cleans deprecated storage slots and it includes a no-op `updateDiscountDistribution` for compatibility.
15. **Upgrade aAAVE Implementation:** `POOL_CONFIGURATOR.updateAToken` updates the AAVE AToken to the `ATokenWithDelegationInstance` (`A_TOKEN_WITH_DELEGATION_IMPL`).
16. **Upgrade vAAVE Implementation:** `POOL_CONFIGURATOR.updateVariableDebtToken` updates the AAVE VariableDebtToken to the standard `VariableDebtTokenInstance` (`V_TOKEN_IMPL`).
17. **Enable GHO Flash Loans:** `POOL_CONFIGURATOR.setReserveFlashLoaning` is called to enable flash loans for the GHO reserve.
18. **Top Up GHO Supply by New Facilitator:** The `GhoDirectMinter` (`FACILITATOR`) calls `mintAndSupply` again. If `capacityFromOldFacilitator` was greater than `levelFromOldFacilitator`, it mints the difference (`capacityFromOldFacilitator - levelFromOldFacilitator`) and supplies it to the Pool. This increases the GHO AToken's total supply and also increases the GHO reserve's `virtualUnderlyingBalance` because the supply operation credits the aToken, and the new Pool treats GHO with virtual accounting.
19. **Migrate GHO Bucket Steward Permissions:** The `IGhoBucketSteward` is configured to give control to the new `FACILITATOR` and remove control from the old `AaveV3EthereumAssets.GHO_A_TOKEN` facilitator.