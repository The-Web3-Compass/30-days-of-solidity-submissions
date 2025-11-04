// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract BasicVoting{
    struct Proposal{
        string name;
        uint256 voteCount;
        uint256 startTime;
        uint256 endTime;
        bool executed;

    }

    Proposal[] public proposals;
    mapping(address=>mapping(uint256=>bool)) public hasVoted;

    function creatProposal(string memory name,uint256 duration)public{
        proposals.push(Proposal({
            name:name,
            voteCount:0,
            startTime:block.timestamp,
            endTime:block.timestamp+duration,
            executed:false
        }));

    }

    function vote(uint256 proposalId)public{
        Proposal storage proposal=proposals[proposalId];
        require(block.timestamp<proposal.endTime,"too late");
        require(block.timestamp>proposal.startTime,"too early");
        require(!hasVoted[msg.sender][proposalId],"already voted");
        hasVoted[msg.sender][proposalId]=true;
        proposal.voteCount++;

    }

    function executedPropsal(uint256 proposalId) public{
        Proposal storage proposal=proposals[proposalId];
        require(block.timestamp>proposal.endTime,"too early");
        require(!proposal.executed,"already executed");
        require(proposal.voteCount>0,"no votes");
        proposal.executed=true;
    }

}