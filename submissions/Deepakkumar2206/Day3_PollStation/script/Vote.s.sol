// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PollStation.sol";

contract VoteScript is Script {
    function run() external {
        vm.startBroadcast();

        // Attach to deployed contract (update with your address)
        PollStation poll = PollStation(payable(0x5FbDB2315678afecb367f032d93F642f64180aa3));

        // Cast a vote for candidate 0 (Alice)
        poll.vote(0);

        vm.stopBroadcast();
    }
}
