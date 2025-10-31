// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PollStation.sol";

contract PollStationTest is Test {
    PollStation poll;

    function setUp() public {
        poll = new PollStation();
    }

    function testAddCandidate() public {
        poll.addCandidate("Alice");
        poll.addCandidate("Bob");

        assertEq(poll.getCandidateCount(), 2);
        assertEq(poll.candidates(0), "Alice");
        assertEq(poll.candidates(1), "Bob");
    }

    function testVote() public {
        poll.addCandidate("Alice");
        poll.addCandidate("Bob");

        poll.vote(1); // Vote for Bob

        assertEq(poll.getVotes(1), 1);
        assertEq(poll.hasVoted(address(this)), true);
        assertEq(poll.votedFor(address(this)), 1);
    }

    function testCannotDoubleVote() public {
        poll.addCandidate("Alice");
        poll.vote(0);

        vm.expectRevert("Already voted");
        poll.vote(0);
    }

    function testInvalidCandidateVote() public {
        vm.expectRevert("Invalid candidate");
        poll.vote(999);
    }
}
