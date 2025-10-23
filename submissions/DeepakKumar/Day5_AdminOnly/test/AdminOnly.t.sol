// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/AdminOnly.sol";

contract AdminOnlyTest is Test {
    AdminOnly admin;
    address owner = address(1);
    address user = address(2);

    function setUp() public {
        vm.prank(owner); // simulate deployment by owner
        admin = new AdminOnly();
    }

    function testAddTreasure() public {
        vm.prank(owner);
        admin.addTreasure(100);
        assertEq(admin.treasure(), 100);
    }

    function testApproveAndWithdraw() public {
        vm.startPrank(owner);
        admin.addTreasure(200);
        admin.approve(user);
        vm.stopPrank();

        vm.prank(user);
        admin.withdraw(50);

        assertEq(admin.treasure(), 150);
        assertTrue(admin.hasWithdrawn(user));
    }

    function test_Revert_WhenWithdrawWithoutApproval() public {
        vm.prank(user);
        vm.expectRevert(); // <--- this is the key fix
        admin.withdraw(10); // should revert
    }

    function testTransferOwnership() public {
        vm.prank(owner);
        admin.transferOwnership(address(3));
        assertEq(admin.owner(), address(3));
    }
}
