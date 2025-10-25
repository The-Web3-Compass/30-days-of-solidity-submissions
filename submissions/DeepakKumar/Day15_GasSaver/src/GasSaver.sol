// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GasSaver {
    struct Proposal {
        string name;
        uint256 voteCount;
    }

    Proposal[] public proposals;
    mapping(address => bool) public hasVoted;

    constructor() {}

    // Add one proposal at a time (simpler than arrays)
    function addProposal(string memory proposalName) external {
        proposals.push(Proposal({name: proposalName, voteCount: 0}));
    }

    function vote(uint256 proposalIndex) external {
        require(!hasVoted[msg.sender], "Already voted");
        hasVoted[msg.sender] = true;

        Proposal storage proposal = proposals[proposalIndex];
        unchecked {
            proposal.voteCount++;
        }
    }

    function getProposal(uint256 index)
        external
        view
        returns (string memory name, uint256 votes)
    {
        Proposal storage proposal = proposals[index];
        return (proposal.name, proposal.voteCount);
    }

    function winningProposal() external view returns (string memory winner) {
        uint256 winningVoteCount;
        uint256 len = proposals.length;

        for (uint256 i; i < len; ) {
            uint256 votes = proposals[i].voteCount;
            if (votes > winningVoteCount) {
                winningVoteCount = votes;
                winner = proposals[i].name;
            }
            unchecked {
                ++i;
            }
        }
    }
}
