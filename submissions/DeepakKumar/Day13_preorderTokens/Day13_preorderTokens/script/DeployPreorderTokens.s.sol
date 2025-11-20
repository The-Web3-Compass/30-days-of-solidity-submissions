// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PreorderTokens.sol";

contract DeployPreorderTokens is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy with 1000 tokens per ETH
        PreorderTokens preorder = new PreorderTokens(1000);

        console.log("PreorderTokens deployed at:", address(preorder));
        console.log("Owner:", preorder.owner());
        console.log("Rate:", preorder.rate());

        vm.stopBroadcast();
    }
}
