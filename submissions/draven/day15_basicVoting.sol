pragma solidity ^0.8.0;

contract BasicVoting {
    struct Proposal {
        string name;
        uint256 voteCount;
        uint256 startTime;
        uint256 endTime;
        bool executed;
    }

    Proposal[] public proposals;
    mapping(address => mapping(uint => bool)) public hasVoted;

    function createProposal(string memory name, uint duration) public {
        proposals.push(Proposal({
            name: name,
            voteCount: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            executed: false
        }));
    }

    function vote(uint proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.startTime, "Too early");
        require(block.timestamp <= proposal.endTime, "Too late");
        require(!hasVoted[msg.sender][proposalId], "Already voted");

        hasVoted[msg.sender][proposalId] = true;
        proposal.voteCount++;
    }

    function executeProposal(uint proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Too early");
        require(!proposal.executed, "Already executed");

        proposal.executed = true;
        // Some execution logic here
    }
}