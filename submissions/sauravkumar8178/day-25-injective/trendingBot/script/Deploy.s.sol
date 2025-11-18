// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/SimpleTradingBot.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        address router = address(0x1);
        SimpleTradingBot bot = new SimpleTradingBot(router);
        vm.stopBroadcast();
    }
}
