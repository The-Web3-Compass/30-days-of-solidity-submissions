// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasSaver {
    struct Proposal {
        string name;
        uint voteCount;
    }

    Proposal[] public proposals;
    mapping(address => bool) public hasVoted;

    constructor(string[] memory proposalNames) {
        //  Using memory for constructor data (cheaper than storage)
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    //  calldata is cheaper for external immutable input
    function vote(uint proposalIndex) external {
        require(!hasVoted[msg.sender], "Already voted");
        require(proposalIndex < proposals.length, "Invalid proposal");

        hasVoted[msg.sender] = true; // 1 storage write (optimized)
        proposals[proposalIndex].voteCount++; // single, direct write
    }

    //  view function, no gas cost for users calling off-chain
    function getWinningProposal() external view returns (string memory winnerName) {
        uint highestVotes;
        uint winningIndex;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > highestVotes) {
                highestVotes = proposals[i].voteCount;
                winningIndex = i;
            }
        }

        winnerName = proposals[winningIndex].name;
    }

    // Helper: returns all proposals with votes
    function getAllProposals() external view returns (Proposal[] memory) {
        return proposals;
    }
}
