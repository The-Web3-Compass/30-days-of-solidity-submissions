// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VaultManager.sol";
import "../src/BasicDepositBox.sol";

contract SafeDepositBoxTest is Test {
    VaultManager manager;
    BasicDepositBox box;
    address user = address(0xBEEF);

    function setUp() public {
        manager = new VaultManager();
        vm.deal(user, 5 ether);
        vm.startPrank(user);
        box = new BasicDepositBox(user);
        manager.registerVault(user, address(box));
        vm.stopPrank();
    }

    function testDepositAndWithdraw() public {
        vm.startPrank(user);
        box.deposit{value: 1 ether}(); // Fixed line
        assertEq(address(box).balance, 1 ether);

        box.withdraw(0.5 ether);
        assertEq(address(box).balance, 0.5 ether);
        vm.stopPrank();
    }
}
