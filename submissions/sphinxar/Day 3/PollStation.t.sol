// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.13;

// import {Test, console} from "forge-std/Test.sol";
// import {PollStation} from "../src/PollStation.sol";

// contract CounterTest is Test {
//     PollStation public pollStation;

//     function setUp() public {
//         pollStation = new PollStation();
//     }

//     function test_SetCandidate() public {
//         pollStation.setCandidate("Tulio");

//         // Assuming candidates is a public array, check the first candidate's value
//         assertEq(pollStation.candidates(0), "Tulio");
//     }

//     function test_Vote() public {
//         pollStation.setCandidate("Tulio");
//         pollStation.setCandidate("Julio");

//         pollStation.vote(1);

//         assertEq(pollStation.votes(address(this)), 1);
//     }

// }
