// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PollStation {

    // Array to store vote counts for each candidate
    uint[] public voteCounts;

    // Mapping to track which candidate an address voted for
    // 0 = not voted, otherwise candidateId + 1
    mapping(address => uint) public votedFor;

    // Constructor: initialize number of candidates
    constructor(uint _numCandidates) {
        require(_numCandidates > 0, "At least one candidate required");
        
        for (uint i = 0; i < _numCandidates; i++) {
            voteCounts.push(0);
        }
    }

    // Vote for a candidate
    function vote(uint _candidateId) public {
        require(_candidateId < voteCounts.length, "Invalid candidate");
        require(votedFor[msg.sender] == 0, "You have already voted");

        voteCounts[_candidateId] += 1;

        // Store candidateId + 1 to differentiate from default 0
        votedFor[msg.sender] = _candidateId + 1;
    }

    // Get total votes for a candidate
    function getVotes(uint _candidateId) public view returns (uint) {
        require(_candidateId < voteCounts.length, "Invalid candidate");
        return voteCounts[_candidateId];
    }

    // Get total number of candidates
    function getTotalCandidates() public view returns (uint) {
        return voteCounts.length;
    }
}