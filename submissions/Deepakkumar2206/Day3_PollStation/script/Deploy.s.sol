// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PollStation.sol";

contract DeployPollStation is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy PollStation contract
        PollStation poll = new PollStation();

        // Add sample candidates
        poll.addCandidate("Alice");
        poll.addCandidate("Bob");

        vm.stopBroadcast();
    }
}
