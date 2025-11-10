// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleIOU.sol";

contract SimpleIOUTest is Test {
    SimpleIOU iou;
    address alice = address(0xA1);
    address bob   = address(0xB2);

    function setUp() public {
        iou = new SimpleIOU();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function testDepositAndBorrow() public {
        vm.startPrank(alice);
        iou.deposit{value: 5 ether}();
        vm.stopPrank();

        vm.startPrank(bob);
        iou.borrow(alice, 2 ether);
        vm.stopPrank();

        assertEq(iou.getDebt(bob, alice), 2 ether);
    }

    function testRepay() public {
        vm.startPrank(alice);
        iou.deposit{value: 5 ether}();
        vm.stopPrank();

        vm.startPrank(bob);
        iou.borrow(alice, 2 ether);
        iou.repay{value: 2 ether}(alice);
        vm.stopPrank();

        assertEq(iou.getDebt(bob, alice), 0);
    }
}
