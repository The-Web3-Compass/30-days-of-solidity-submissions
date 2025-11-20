// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/WeatherOracleMock.sol";

contract DeployOracle is Script {
    function run() external {
        uint256 key = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(key);

        WeatherOracleMock oracle = new WeatherOracleMock();
        console.log("Oracle deployed at:", address(oracle));

        vm.stopBroadcast();
    }
}
