// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GasSaver.sol";

contract GasSaverTest is Test {
    GasSaver gasSaver;

    function setUp() public {
        gasSaver = new GasSaver();

        // Add proposals one by one (no arrays)
        gasSaver.addProposal("Yes");
        gasSaver.addProposal("No");
    }

    function testVoteOnce() public {
        gasSaver.vote(0);
        (string memory name, uint256 votes) = gasSaver.getProposal(0);
        assertEq(votes, 1);
        assertEq(name, "Yes");
    }

    function testCannotVoteTwice() public {
        gasSaver.vote(1);
        vm.expectRevert("Already voted");
        gasSaver.vote(1);
    }

    function testWinningProposal() public {
        gasSaver.vote(0);
        string memory winner = gasSaver.winningProposal();
        assertEq(winner, "Yes");
    }
}
