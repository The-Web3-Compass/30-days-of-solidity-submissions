/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    // 1. Array: Stores the vote counts. 
    // The index is the Candidate ID (e.g., candidate 0, candidate 1)
    uint256[] public voteCounts;

    // 2. Mapping: Remembers *which* candidate a specific address voted for
    mapping(address => uint256) public votedFor;

    // Security Mapping: Tracks if an address has already cast a vote
    mapping(address => bool) public hasVoted;

    // Event to log votes to the blockchain
    event Voted(address indexed voter, uint256 candidateId);

    // When deploying, we specify how many candidates are running
    constructor(uint256 _numberOfCandidates) {
        require(_numberOfCandidates > 0, "Must have at least one candidate");
        // Initialize the array with 0 votes for each candidate
        for(uint256 i = 0; i < _numberOfCandidates; i++) {
            voteCounts.push(0);
        }
    }

    // The main voting logic
    function vote(uint256 candidateId) public {
        // Check 1: Prevent double voting
        require(!hasVoted[msg.sender], "You have already voted!");
        
        // Check 2: Ensure the candidate actually exists in our array
        require(candidateId < voteCounts.length, "Invalid candidate ID");

        // Record the vote state
        hasVoted[msg.sender] = true;         // Mark them as having voted
        votedFor[msg.sender] = candidateId;  // Remember who they chose
        voteCounts[candidateId]++;           // Increment the candidate's total in the array

        emit Voted(msg.sender, candidateId);
    }

    // A helper function to see all results at once
    function getAllResults() public view returns (uint256[] memory) {
        return voteCounts;
    }
}