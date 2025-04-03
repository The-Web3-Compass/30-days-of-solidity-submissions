/*---------------------------------------------------------------------------
  File:   PollStation.sol
  Author: Marion Bohr
  Date:   04/03/2025
  Description:
    Let's build a simple polling station! Users will be able to vote for 
    their favorite candidates. You'll use lists (arrays, `uint[]`) to store 
    candidate details. You'll also create a system (mappings, 
    `mapping(address => uint)`) to remember who (their `address`) voted for 
    which candidate. Think of it as a digital voting booth. This teaches you 
    how to manage data in a structured way.
----------------------------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract PollStation {
    // Candidate structure
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Array to store all candidates
    Candidate[] public candidates;
    
    // Mapping to track which address has voted
    mapping(address => bool) public voters;
    
    // Mapping to track which candidate each voter chose
    mapping(address => uint) public votes;
    
    // Event to log when a vote is cast
    event VoteCast(address indexed voter, uint indexed candidateId);
    
    // Constructor to initialize with some candidates
    constructor(string[] memory candidateNames) {
        for (uint i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate({
                id: i,
                name: candidateNames[i],
                voteCount: 0
            }));
        }
    }
    
    // Function to vote for a candidate
    function vote(uint candidateId) public {
        require(candidateId < candidates.length, "Invalid candidate ID");
        require(!voters[msg.sender], "You have already voted");
        
        candidates[candidateId].voteCount++;
        voters[msg.sender] = true;
        votes[msg.sender] = candidateId;
        
        emit VoteCast(msg.sender, candidateId);
    }
    
    // Function to get the total number of candidates
    function getCandidateCount() public view returns (uint) {
        return candidates.length;
    }
    
    // Function to get all candidates with their vote counts
    function getAllCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }
    
    // Function to check if an address has voted
    function hasVoted(address voter) public view returns (bool) {
        return voters[voter];
    }
    
    // Function to get the winner (returns first candidate if tie)
    function getWinner() public view returns (uint winnerId) {
        uint winningVoteCount = 0;
        
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winnerId = i;
            }
        }
    }
}