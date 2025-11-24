// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {

    string[] public candidates;

    mapping(uint => uint) public votes;

    mapping(address => bool) public hasVoted;

    constructor(string[] memory _candidates) {
        candidates = _candidates;
    }

    function vote(uint candidateId) external {
        require(candidateId < candidates.length, "Invalid candidate ID");
        require(!hasVoted[msg.sender], "You have already voted");

        votes[candidateId]++;
        hasVoted[msg.sender] = true;
    }

    function getVotes(uint candidateId) external view returns (uint) {
        require(candidateId < candidates.length, "Invalid candidate ID");
        return votes[candidateId];
    }

    function getAllCandidates() external view returns (string[] memory) {
        return candidates;
    }
}