// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EtherPiggyBank.sol";

contract EtherPiggyBankTest is Test {
    EtherPiggyBank piggyBank;
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        piggyBank = new EtherPiggyBank();

        // Give user1 and user2 some Ether to test with
        vm.deal(user1, 10 ether);
        vm.deal(user2, 5 ether);
    }

    function testDeposit() public {
        // User1 deposits 2 Ether
        vm.startPrank(user1);
        piggyBank.deposit{value: 2 ether}();
        vm.stopPrank();

        // Assertions
        assertEq(piggyBank.balances(user1), 2 ether);
        assertEq(piggyBank.getContractBalance(), 2 ether);
    }

    function testWithdraw() public {
        // User1 deposits first
        vm.startPrank(user1);
        piggyBank.deposit{value: 3 ether}();
        vm.stopPrank();

        // Verify contract balance before withdrawal
        assertEq(piggyBank.getContractBalance(), 3 ether);
        assertEq(piggyBank.balances(user1), 3 ether);

        // User1 withdraws 1 Ether
        vm.startPrank(user1);
        piggyBank.withdraw(1 ether);
        vm.stopPrank();

        // Assertions after withdrawal
        assertEq(piggyBank.balances(user1), 2 ether);
        assertEq(piggyBank.getContractBalance(), 2 ether);
    }

    function testMultipleUsers() public {
        // User1 deposits 1 Ether
        vm.startPrank(user1);
        piggyBank.deposit{value: 1 ether}();
        vm.stopPrank();

        // User2 deposits 2 Ether
        vm.startPrank(user2);
        piggyBank.deposit{value: 2 ether}();
        vm.stopPrank();

        // Assertions
        assertEq(piggyBank.balances(user1), 1 ether);
        assertEq(piggyBank.balances(user2), 2 ether);
        assertEq(piggyBank.getContractBalance(), 3 ether);
    }
}
