// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/MyCollectible.sol";

contract DeployMyCollectible is Script {
    function run() external {
        vm.startBroadcast();
        new MyCollectible();
        vm.stopBroadcast();
    }
}
