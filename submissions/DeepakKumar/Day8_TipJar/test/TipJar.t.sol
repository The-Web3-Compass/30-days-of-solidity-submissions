// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/TipJar.sol";

contract TipJarTest is Test {
    TipJar tipjar;
    address user1 = address(0x123);
    address owner = address(this);

    // Allow this contract to receive ETH
    receive() external payable {}

    function setUp() public {
        tipjar = new TipJar();
        vm.deal(user1, 10 ether);
    }

    function testSendTip() public {
        vm.prank(user1);
        tipjar.sendTip{value: 1 ether}();
        assertEq(tipjar.totalTips(), 1 ether);
        assertEq(tipjar.getContribution(user1), 1 ether);
    }

    function testSendTipInUSD() public {
        vm.prank(user1);
        tipjar.sendTipInUSD{value: 0.005 ether}(10);
        assertEq(tipjar.getContribution(user1), 0.005 ether);
    }

    function testWithdraw() public {
        vm.prank(user1);
        tipjar.sendTip{value: 2 ether}();

        uint256 before = address(this).balance;
        tipjar.withdraw();
        uint256 afterBalance = address(this).balance;

        assertGt(afterBalance, before);
    }
}
