// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {DataTypes} from "aave-v3-origin/contracts/protocol/pool/PoolStorage.sol";

library CustomInitialize {
  function _initialize(
    uint256 reservesCount,
    mapping(uint256 => address) storage _reservesList,
    mapping(address => DataTypes.ReserveData) storage _reserves
  ) internal {
    for (uint256 i = 0; i < reservesCount; i++) {
      address currentReserveAddress = _reservesList[i];
      DataTypes.ReserveData storage currentReserve = _reserves[currentReserveAddress];
      uint128 currentVB = currentReserve.__deprecatedVirtualUnderlyingBalance;
      if (currentVB != 0) {
        currentReserve.virtualUnderlyingBalance = currentVB;
        currentReserve.__deprecatedVirtualUnderlyingBalance = 0;
      }
    }
  }
}
