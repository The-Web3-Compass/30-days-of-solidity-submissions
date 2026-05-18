// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/GasEfficientVoting.sol";

contract NaiveVoting {
    struct Proposal {
        bool isActive;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline;
        bytes32 descriptionHash;
    }

    Proposal[] internal proposals;
    mapping(address => mapping(uint256 => bool)) public voterRegistry;

    function createProposal(bytes32 descriptionHash, uint32 durationSeconds) external returns (uint256 proposalId) {
        require(durationSeconds > 0, "duration=0");

        proposalId = proposals.length;
        proposals.push(
            Proposal({
                isActive: true,
                yesVotes: 0,
                noVotes: 0,
                deadline: block.timestamp + durationSeconds,
                descriptionHash: descriptionHash
            })
        );
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.isActive && block.timestamp <= proposal.deadline, "closed");
        require(!voterRegistry[msg.sender][proposalId], "already voted");

        voterRegistry[msg.sender][proposalId] = true;

        if (support) {
            proposal.yesVotes += 1;
        } else {
            proposal.noVotes += 1;
        }
    }
}

contract VoterProxy {
    function voteNaive(NaiveVoting naive, uint256 proposalId, bool support) external {
        naive.vote(proposalId, support);
    }

    function voteOptimized(GasEfficientVoting optimized, uint256 proposalId, bool support) external {
        optimized.vote(proposalId, support);
    }
}

contract GasEfficientVotingGasTest {
    GasEfficientVoting internal optimized;
    NaiveVoting internal naive;

    bytes32 internal constant DESCRIPTION_HASH = keccak256("day-15-proposal");

    function setUp() public {
        optimized = new GasEfficientVoting();
        naive = new NaiveVoting();
    }

    function testGas_createProposal_naive() public {
        naive.createProposal(DESCRIPTION_HASH, 1 days);
    }

    function testGas_createProposal_optimized() public {
        optimized.createProposal(DESCRIPTION_HASH, 1 days);
    }

    function testGas_vote_naive() public {
        uint256 proposalId = naive.createProposal(DESCRIPTION_HASH, 1 days);
        naive.vote(proposalId, true);
    }

    function testGas_vote_optimized() public {
        uint256 proposalId = optimized.createProposal(DESCRIPTION_HASH, 1 days);
        optimized.vote(proposalId, true);
    }
}
