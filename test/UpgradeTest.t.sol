// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {
  ProtocolV3TestBase,
  IPool,
  IPoolDataProvider,
  IPoolAddressesProvider,
  IERC20,
  DataTypes,
  ReserveConfiguration,
  SafeERC20
} from "../src/aave-helpers/ProtocolV3TestBase.sol";

import {IFlashLoanReceiver} from "aave-v3-origin/contracts/misc/flashloan/interfaces/IFlashLoanReceiver.sol";

import {UpgradePayload} from "../src/UpgradePayload.sol";

abstract contract UpgradeTest is ProtocolV3TestBase, IFlashLoanReceiver {
  using SafeERC20 for IERC20;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  string public NETWORK;
  uint256 public immutable BLOCK_NUMBER;

  IPool public override POOL;
  IPoolAddressesProvider public override ADDRESSES_PROVIDER;

  UpgradePayload private _payloadForFlashloan;

  constructor(string memory network, uint256 blocknumber) {
    NETWORK = network;
    BLOCK_NUMBER = blocknumber;
  }

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl(NETWORK), BLOCK_NUMBER);
  }

  function test_execution() public virtual {
    executePayload(vm, _getTestPayload());
  }

  function test_diff() external virtual {
    UpgradePayload _payload = UpgradePayload(_getTestPayload());

    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(address(_payload.POOL_ADDRESSES_PROVIDER()));
    IPool pool = IPool(addressesProvider.getPool());

    defaultTest(
      string(abi.encodePacked(vm.toString(block.chainid), "_", vm.toString(address(pool)))), pool, address(_payload)
    );
  }

  function test_upgrade() public virtual {
    UpgradePayload _payload = UpgradePayload(_getTestPayload());

    executePayload(vm, address(_payload));

    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(address(_payload.POOL_ADDRESSES_PROVIDER()));
    IPool pool = IPool(addressesProvider.getPool());
    IPoolDataProvider poolDataProvider = IPoolDataProvider(addressesProvider.getPoolDataProvider());

    assertEq(pool.FLASHLOAN_PREMIUM_TO_PROTOCOL(), 100_00);

    address[] memory reserves = pool.getReservesList();
    for (uint256 i = 0; i < reserves.length; i++) {
      address reserve = reserves[i];
      assertTrue(poolDataProvider.getIsVirtualAccActive(reserve));

      address aToken = pool.getReserveAToken(reserve);

      assertGe(IERC20(reserve).balanceOf(aToken), pool.getVirtualUnderlyingBalance(reserve));
    }
  }

  function test_gas() external {
    executePayload(vm, address(_getPayload()));
    vm.snapshotGasLastCall("Execution", NETWORK);
  }

  function test_flashloan_attack() public {
    _payloadForFlashloan = UpgradePayload(_getTestPayload());

    POOL = _payloadForFlashloan.POOL();
    ADDRESSES_PROVIDER = _payloadForFlashloan.POOL_ADDRESSES_PROVIDER();

    address[] memory reserves = POOL.getReservesList();
    uint256[] memory oldVirtualUnderlyingBalances = new uint256[](reserves.length);

    uint256 length;
    address[] memory filteredReserves = new address[](reserves.length);
    uint256[] memory amounts = new uint256[](reserves.length);
    uint256[] memory interestRateModes = new uint256[](reserves.length);
    for (uint256 i = 0; i < reserves.length; i++) {
      oldVirtualUnderlyingBalances[i] = POOL.getVirtualUnderlyingBalance(reserves[i]);

      DataTypes.ReserveConfigurationMap memory configuration = POOL.getConfiguration(reserves[i]);

      if (configuration.getPaused() || !configuration.getActive() || !configuration.getFlashLoanEnabled()) {
        continue;
      }

      filteredReserves[length] = reserves[i];
      amounts[length] = oldVirtualUnderlyingBalances[i];
      interestRateModes[length] = 0;

      ++length;
    }
    assembly {
      mstore(filteredReserves, length)
      mstore(amounts, length)
      mstore(interestRateModes, length)
    }

    POOL.flashLoan({
      receiverAddress: address(this),
      assets: filteredReserves,
      amounts: amounts,
      interestRateModes: interestRateModes,
      onBehalfOf: address(this),
      params: "",
      referralCode: 0
    });

    for (uint256 i = 0; i < reserves.length; i++) {
      assertEq(POOL.getVirtualUnderlyingBalance(reserves[i]), oldVirtualUnderlyingBalances[i]);
    }
  }

  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address, /* initiator */
    bytes calldata /* params */
  ) external returns (bool) {
    for (uint256 i = 0; i < assets.length; i++) {
      deal2(assets[i], address(this), amounts[i] + premiums[i]);

      IERC20(assets[i]).forceApprove(msg.sender, amounts[i] + premiums[i]);
    }

    executePayload(vm, address(_payloadForFlashloan));

    return true;
  }

  function _getTestPayload() internal returns (address) {
    address deployed = _getDeployedPayload();
    if (deployed == address(0)) return _getPayload();
    return deployed;
  }

  function _getPayload() internal virtual returns (address);

  function _getDeployedPayload() internal virtual returns (address);
}
