// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/AMMFactory.sol";
import "../src/AMMPair.sol";
import "../src/MockERC20.sol";

contract AddLiquidityScript is Script {
    function run() external {
        // Set env vars before running:
        // TOKEN_A, TOKEN_B, FACTORY, PROVIDER_PRIVATE_KEY (optional if broadcast)
        address tokenAAddr = vm.envAddress("TOKEN_A");
        address tokenBAddr = vm.envAddress("TOKEN_B");
        address factoryAddr = vm.envAddress("FACTORY");

        require(tokenAAddr != address(0) && tokenBAddr != address(0) && factoryAddr != address(0), "ENV_VARS_NOT_SET");

        AMMFactory factory = AMMFactory(factoryAddr);

        vm.startBroadcast();

        // create pair if not exists
        if (factory.getPair(tokenAAddr, tokenBAddr) == address(0)) {
            factory.createPair(tokenAAddr, tokenBAddr);
        }

        address pairAddr = factory.getPair(tokenAAddr, tokenBAddr);
        AMMPair pair = AMMPair(pairAddr);
        MockERC20 tokenA = MockERC20(tokenAAddr);
        MockERC20 tokenB = MockERC20(tokenBAddr);

        uint256 amount = 100 ether;

        // approve pair
        tokenA.approve(pairAddr, amount);
        tokenB.approve(pairAddr, amount);

        // call addLiquidity from this account
        pair.addLiquidity(amount, amount);

        console.log("Added liquidity to pair:", pairAddr);

        vm.stopBroadcast();
    }
}
