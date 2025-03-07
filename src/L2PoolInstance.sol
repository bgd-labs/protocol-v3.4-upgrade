// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {L2Pool} from "aave-v3-origin/contracts/protocol/pool/L2Pool.sol";
import {IPoolAddressesProvider} from "aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol";
import {IReserveInterestRateStrategy} from "aave-v3-origin/contracts/interfaces/IReserveInterestRateStrategy.sol";

import {PoolInstance} from "./PoolInstance.sol";

contract L2PoolInstance is L2Pool, PoolInstance {
  constructor(IPoolAddressesProvider provider, IReserveInterestRateStrategy interestRateStrategy)
    PoolInstance(provider, interestRateStrategy)
  {}
}
