// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/TipJar.sol";

contract DeployTipJar is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        TipJar tipjar = new TipJar();

        console.log(" TipJar deployed to:", address(tipjar));
        console.log("Owner:", msg.sender);

        vm.stopBroadcast();
    }
}
