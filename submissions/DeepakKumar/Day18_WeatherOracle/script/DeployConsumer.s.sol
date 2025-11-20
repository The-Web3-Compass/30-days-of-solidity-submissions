// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/WeatherConsumer.sol";

contract DeployConsumer is Script {
    function run() external {
        uint256 key = vm.envUint("PRIVATE_KEY");
        address oracle = vm.envAddress("ORACLE_ADDRESS");

        vm.startBroadcast(key);
        WeatherConsumer consumer = new WeatherConsumer(oracle);
        console.log("Consumer deployed at:", address(consumer));
        vm.stopBroadcast();
    }
}
