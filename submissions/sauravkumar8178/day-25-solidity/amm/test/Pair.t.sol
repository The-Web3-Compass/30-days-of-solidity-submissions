// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/MockERC20.sol";
import "../src/AMMFactory.sol";
import "../src/AMMPair.sol";

contract PairTest is Test {
    MockERC20 tokenA;
    MockERC20 tokenB;
    AMMFactory factory;
    AMMPair pair;

    address alice = address(0xA11ce);
    address bob = address(0xB0b);

    function setUp() public {
        tokenA = new MockERC20("TokenA", "TKA", 1_000_000 ether);
        tokenB = new MockERC20("TokenB", "TKB", 1_000_000 ether);

        factory = new AMMFactory();
        factory.createPair(address(tokenA), address(tokenB));
        address pairAddr = factory.getPair(address(tokenA), address(tokenB));
        pair = AMMPair(pairAddr);

        // distribute funds
        tokenA.transfer(alice, 1000 ether);
        tokenB.transfer(alice, 1000 ether);
        tokenA.transfer(bob, 1000 ether);
        tokenB.transfer(bob, 1000 ether);
    }

    function testAddLiquidity() public {
        // Alice approves and adds liquidity
        vm.prank(alice);
        tokenA.approve(address(pair), 100 ether);
        vm.prank(alice);
        tokenB.approve(address(pair), 100 ether);
        vm.prank(alice);
        pair.addLiquidity(100 ether, 100 ether);

        (uint112 r0, uint112 r1) = pair.getReserves();
        assertEq(uint256(r0), 100 ether);
        assertEq(uint256(r1), 100 ether);

        assertGt(pair.totalSupply(), 0);
        assertEq(pair.balanceOf(alice) > 0, true);
    }

    function testSwap() public {
        // setup liquidity from Alice
        vm.prank(alice);
        tokenA.approve(address(pair), 100 ether);
        vm.prank(alice);
        tokenB.approve(address(pair), 100 ether);
        vm.prank(alice);
        pair.addLiquidity(100 ether, 100 ether);

        (uint112 r0Before, uint112 r1Before) = pair.getReserves();

        // Bob swaps tokenA -> tokenB: transfer 1 tokenA to pair, then call swap for expected amountOut
        vm.prank(bob);
        tokenA.transfer(address(pair), 1 ether);

        // compute amountOut using formula
        (uint112 r0, uint112 r1) = pair.getReserves();
        uint256 reserveIn = uint256(r0);
        uint256 reserveOut = uint256(r1);
        uint256 amountIn = 1 ether;
        uint256 amountInWithFee = (amountIn * pair.feeNumerator()) / pair.feeDenominator();
        uint256 amountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);

        vm.prank(bob);
        pair.swap(0, amountOut, bob);

        (uint112 r0After, uint112 r1After) = pair.getReserves();
        assertTrue(uint256(r0After) > reserveIn);
        assertTrue(uint256(r1After) < reserveOut);
    }
}
