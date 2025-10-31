// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VaultManager.sol";
import "../src/BasicDepositBox.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        VaultManager manager = new VaultManager();
        BasicDepositBox box = new BasicDepositBox(msg.sender);
        manager.registerVault(msg.sender, address(box));
        vm.stopBroadcast();
    }
}
