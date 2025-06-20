// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {PoolConfiguratorInstance} from "aave-v3-origin/contracts/instances/PoolConfiguratorInstance.sol";
import {IPoolAddressesProvider} from "aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "aave-v3-origin/contracts/interfaces/IPool.sol";

contract PoolConfiguratorWithCustomInitialize is PoolConfiguratorInstance {
  function initialize(IPoolAddressesProvider provider) public virtual override initializer {
    super.initialize(provider);

    // @note This `initialize` function
    //       must be executed *before* the main `Pool` contract is upgraded to v3.4.
    //       This is necessary to fetch the dynamic `FLASHLOAN_PREMIUM_TO_PROTOCOL` value
    //       from the v3.3 `Pool`'s storage. After the `Pool` contract is upgraded to v3.4,
    //       its `FLASHLOAN_PREMIUM_TO_PROTOCOL` function will become a constant and always
    //       return `100_00`, making the old dynamic value inaccessible.
    uint128 oldFlashloanPremiumToProtocol = _pool.FLASHLOAN_PREMIUM_TO_PROTOCOL();
    if (oldFlashloanPremiumToProtocol != 100_00) {
      emit FlashloanPremiumToProtocolUpdated({
        oldFlashloanPremiumToProtocol: oldFlashloanPremiumToProtocol,
        newFlashloanPremiumToProtocol: 100_00
      });
    }
  }
}