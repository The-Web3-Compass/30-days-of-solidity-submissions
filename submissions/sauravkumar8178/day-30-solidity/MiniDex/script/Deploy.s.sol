// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/ExchangeFactory.sol";
import "../src/MockERC20.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        ExchangeFactory factory = new ExchangeFactory();
        MockERC20 tokenA = new MockERC20("Token A", "TKA");
        MockERC20 tokenB = new MockERC20("Token B", "TKB");

        // Mint some tokens to deployer for initial liquidity (example)
        tokenA.mint(msg.sender, 1_000_000 ether);
        tokenB.mint(msg.sender, 1_000_000 ether);

        vm.stopBroadcast();
    }
}
