// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ExchangeFactory.sol";
import "../src/MockERC20.sol";
import "../src/ExchangePair.sol";

contract ExchangeTest is Test {
    ExchangeFactory factory;
    MockERC20 tokenA;
    MockERC20 tokenB;
    ExchangePair pair;

    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        factory = new ExchangeFactory();
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");

        tokenA.mint(address(this), 1_000_000 ether);
        tokenB.mint(address(this), 1_000_000 ether);

        address pairAddr = factory.createPair(address(tokenA), address(tokenB));
        pair = ExchangePair(payable(pairAddr));
    }

    function testAddLiquidityAndSwap() public {
        // Approve/transfer tokens into pair
        tokenA.transfer(address(pair), 1000 ether);
        tokenB.transfer(address(pair), 1000 ether);
        pair.mint(address(this));
        (uint112 r0, uint112 r1) = pair.getReserves();
        assertEq(uint256(r0), 1000 ether);
        assertEq(uint256(r1), 1000 ether);

        // Swap: give 10 tokenA and take tokenB out
        tokenA.transfer(address(pair), 10 ether);
        // compute expected amount out roughly using x*y invariant after fee; but we will call swap with amount1Out = 9 (approx)
        // here for simplicity we do a small swap and assert reserves update
        pair.swap(0, 9 ether, address(this));
        (uint112 r0_after, uint112 r1_after) = pair.getReserves();
        assertTrue(uint256(r0_after) > uint256(r0));
        assertTrue(uint256(r1_after) < uint256(r1));
    }
}
