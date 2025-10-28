// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/SimpleDAO.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        // Example: 1 day voting period, quorum 3
        new SimpleDAO(24 hours, 3);
        vm.stopBroadcast();
    }
}

