//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BasicVoting {
    struct Proposal {
        string name;
        uint256 voteCount;
        uint256 startTime;
        uint256 endTime;
        bool ended;
    }

    Proposal[] public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    function createProposal(string calldata _name, uint256 _duration) external {
        proposals.push(Proposal({
            name: _name,
            voteCount: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            ended: false
        }));
    }

    function vote(uint256 _proposalID) external {
        Proposal storage proposal = proposals[_proposalID];
        require(_proposalID < proposals.length, "Invalid proposal ID");
        require(block.timestamp >= proposal.startTime, "Voting not started yet");
        require(block.timestamp <= proposal.endTime, "Voting has already ended");
        require(!hasVoted[msg.sender][_proposalID], "You have already voted");

        proposal.voteCount++;
        hasVoted[msg.sender][_proposalID] = true;
    }

    function finilizeProposal(uint256 _proposalID) external {
        Proposal storage proposal = proposals[_proposalID];
        require(_proposalID < proposals.length, "Invalid proposal ID");
        require(block.timestamp > proposal.endTime, "Finilize too early");
        require(!proposal.ended, "Proposal is already ended");

        proposal.ended = true;
    }
}