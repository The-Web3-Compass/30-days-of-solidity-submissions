// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    uint[] public votes;
    mapping(address => uint) public votedFor;
    mapping(address => bool) public hasVoted;

    constructor(uint _numCandidates) {
        votes = new uint[](_numCandidates);
    }

    function vote(uint _candidateId) public {
        require(!hasVoted[msg.sender], "You have already voted");
        require(_candidateId < votes.length, "Invalid candidate");

        votes[_candidateId] += 1;
        votedFor[msg.sender] = _candidateId;
        hasVoted[msg.sender] = true;
    }

    function getVotes(uint _candidateId) public view returns (uint) {
        require(_candidateId < votes.length, "Invalid candidate");
        return votes[_candidateId];
    }

    function getMyVote() public view returns (uint) {
        require(hasVoted[msg.sender], "You have not voted yet");
        return votedFor[msg.sender];
    }

    function getCandidatesCount() public view returns (uint) {
        return votes.length;
    }
}