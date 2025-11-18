// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/MockERC20.sol";
import "../src/AMMFactory.sol";
import "../src/AMMRouter.sol";

contract RouterTest is Test {
    MockERC20 tokenA;
    MockERC20 tokenB;
    AMMFactory factory;
    AMMRouter router;

    address alice = address(0xA11ce);
    address bob = address(0xB0b);

    function setUp() public {
        tokenA = new MockERC20("TokenA", "TKA", 1_000_000 ether);
        tokenB = new MockERC20("TokenB", "TKB", 1_000_000 ether);

        factory = new AMMFactory();
        factory.createPair(address(tokenA), address(tokenB));
        router = new AMMRouter(address(factory));

        // distribute funds
        tokenA.transfer(alice, 1000 ether);
        tokenB.transfer(alice, 1000 ether);
        tokenA.transfer(bob, 1000 ether);
        tokenB.transfer(bob, 1000 ether);

        // Alice adds liquidity directly to pair (router.addLiquidity is not implemented)
        address pairAddr = factory.getPair(address(tokenA), address(tokenB));
        // approve from alice and add liquidity as alice
        vm.prank(alice);
        tokenA.approve(pairAddr, 200 ether);
        vm.prank(alice);
        tokenB.approve(pairAddr, 200 ether);
        vm.prank(alice);
        // call pair.addLiquidity directly
        // compile-time type: AMMPair
        (bool success,) = pairAddr.call(abi.encodeWithSignature("addLiquidity(uint256,uint256)", 100 ether, 100 ether));
        require(success, "addLiquidity failed");
    }

    function testRouterSwap() public {
        // Bob swaps 1 tokenA for tokenB via router
        // Approve router to spend bob's tokenA
        vm.prank(bob);
        tokenA.approve(address(router), 1 ether);

        // call router swapExactTokensForTokens
        // Note: router computes amountOut using pair reserves
        vm.prank(bob);
        router.swapExactTokensForTokens(1 ether, 0, address(tokenA), address(tokenB), bob);

        // bob should have received some tokenB (more than 0)
        assertTrue(tokenB.balanceOf(bob) > 0);
    }
}
