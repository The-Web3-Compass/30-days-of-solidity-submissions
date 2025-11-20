// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VaultMaster.sol";

contract VaultMasterTest is Test {
    VaultMaster vault;
    address owner = address(this);
    address payable user = payable(address(0xBEEF));

    function setUp() public {
        vault = new VaultMaster();
    }

    function testDepositAndWithdraw() public {
        vm.deal(owner, 5 ether);
        vault.deposit{value: 2 ether}();
        assertEq(vault.getVaultBalance(), 2 ether);

        vault.withdraw(user, 1 ether);
        assertEq(vault.getVaultBalance(), 1 ether);
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.deal(address(vault), 2 ether);
        vm.startPrank(user);
        vm.expectRevert("Not the owner");
        vault.withdraw(user, 1 ether);
        vm.stopPrank();
    }

    function testOwnershipTransfer() public {
        address newOwner = address(0xABCD);
        vault.transferOwnership(newOwner);
        assertEq(vault.owner(), newOwner);
    }
}
