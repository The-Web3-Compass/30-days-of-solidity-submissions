// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyFirstToken.sol";

contract MyFirstTokenTest is Test {
    MyFirstToken token;
    address alice = address(0x123);
    address bob = address(0x456);

    function setUp() public {
        token = new MyFirstToken(1000);
    }

    function testInitialSupply() public view{
        assertEq(token.totalSupply(), 1000 * 10 ** 18);
        assertEq(token.balanceOf(address(this)), 1000 * 10 ** 18);
    }

    function testTransfer() public {
        token.transfer(alice, 100 * 10 ** 18);
        assertEq(token.balanceOf(alice), 100 * 10 ** 18);
    }

    function testApproveAndTransferFrom() public {
        token.approve(alice, 50 * 10 ** 18);
        vm.prank(alice);
        token.transferFrom(address(this), bob, 50 * 10 ** 18);
        assertEq(token.balanceOf(bob), 50 * 10 ** 18);
    }
}
