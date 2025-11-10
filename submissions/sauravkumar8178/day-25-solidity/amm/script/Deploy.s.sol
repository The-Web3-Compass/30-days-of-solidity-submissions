// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/MockERC20.sol";
import "../src/AMMFactory.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        MockERC20 tokenA = new MockERC20("TokenA", "TKA", 1_000_000 ether);
        MockERC20 tokenB = new MockERC20("TokenB", "TKB", 1_000_000 ether);

        AMMFactory factory = new AMMFactory();

        console.log("TokenA:", address(tokenA));
        console.log("TokenB:", address(tokenB));
        console.log("Factory:", address(factory));

        vm.stopBroadcast();
    }
}
