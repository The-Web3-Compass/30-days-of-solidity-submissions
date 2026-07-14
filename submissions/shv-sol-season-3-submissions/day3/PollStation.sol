// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PollStation
 * @dev A simple voting contract where users can vote for candidates by index.
 * Each address can vote only once, and votes are counted per candidate.
 */

contract PollStation {
    uint[] public votes;

    mapping(address => bool) public hasVoted;

    constructor(uint _numCandidates) {
        votes = new uint[](_numCandidates);
    }

    // Function to vote for a candidate by index
    function vote(uint candidateIndex) public {
        require(!hasVoted[msg.sender], "You have already voted.");
        require(candidateIndex < votes.length, "Invalid candidate index.");

        votes[candidateIndex] += 1;
        hasVoted[msg.sender] = true;
    }

    // View function to get total votes for a candidate
    function getVotes(uint candidateIndex) public view returns (uint) {
        require(candidateIndex < votes.length, "Invalid candidate index.");
        return votes[candidateIndex];
    }

    // View function to get total number of candidates
    function getNumCandidates() public view returns (uint) {
        return votes.length;
    }
}
