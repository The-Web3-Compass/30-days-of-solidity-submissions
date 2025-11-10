// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Calculator.sol";
import "../src/SmartCalculator.sol";

contract DeploySmartCalculator is Script {
    function run() external {
        vm.startBroadcast();

        Calculator calculator = new Calculator();
        SmartCalculator smartCalculator = new SmartCalculator(address(calculator));

        console.log("Calculator deployed at:", address(calculator));
        console.log("SmartCalculator deployed at:", address(smartCalculator));

        vm.stopBroadcast();
    }
}
