// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PreorderTokens.sol";

contract PreorderTokensTest is Test {
    PreorderTokens preorder;
    address user = address(0x123);

    function setUp() public {
        preorder = new PreorderTokens(1000);
        vm.deal(user, 10 ether);
    }

    function testBuyTokens() public {
        vm.startPrank(user);
        preorder.buyTokens{value: 1 ether}();
        vm.stopPrank();

        uint256 balance = preorder.balanceOf(user);
        assertEq(balance, 1000 * 10 ** preorder.decimals());
    }

    function testWithdrawFunds() public {
        vm.startPrank(user);
        preorder.buyTokens{value: 1 ether}();
        vm.stopPrank();

        uint256 before = address(preorder.owner()).balance;
        preorder.withdrawFunds();
        uint256 afterBal = address(preorder.owner()).balance;

        assertGt(afterBal, before);
    }

    function testToggleSale() public {
        preorder.toggleSale(false);
        assertEq(preorder.saleActive(), false);
    }
}
