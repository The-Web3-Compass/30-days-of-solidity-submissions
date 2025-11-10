// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AdvancedLendingPool.sol";
import "../src/MockStableToken.sol";

contract LendingPoolTest is Test {

    AdvancedLendingPool pool;
    MockStableToken token;
    address user = address(1);
    address liquidator = address(2);

    function setUp() public {
        token = new MockStableToken();
        pool = new AdvancedLendingPool(IERC20(address(token)));
        token.mint(address(pool), 1_000_000 ether);

        // give tokens to liquidator
        token.mint(liquidator, 1000 ether);

        // deal ETH to users
        vm.deal(user, 10 ether);
        vm.deal(liquidator, 5 ether);
    }

    function testDepositETH() public {
        vm.prank(user);
        pool.depositETH{value: 1 ether}();

        assertEq(pool.depositBalances(user), 1 ether);
    }

    function testCollateralAndBorrow() public {
        // deposit collateral
        vm.prank(user);
        pool.depositCollateral{value: 2 ether}();

        // borrow 1 ETH worth of stablecoin
        vm.prank(user);
        pool.borrow(1 ether);

        assertEq(pool.borrowBalances(user), 1 ether);
        assertEq(token.balanceOf(user), 1 ether);
    }
}
