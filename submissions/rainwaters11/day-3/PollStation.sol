// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    // Arrays and Mappings
    uint256[] public voteCounts;
    mapping(address => uint256) public votedFor;
    mapping(address => bool) public hasVoted;
    
    // NEW: Tracks how much voting power an address has received from others
    mapping(address => uint256) public delegatedWeight;

    // Events
    event Voted(address indexed voter, uint256 candidateId, uint256 weight);
    event Delegated(address indexed from, address indexed to);

    constructor(uint256 _numberOfCandidates) {
        require(_numberOfCandidates > 0, "Must have at least one candidate");
        for(uint256 i = 0; i < _numberOfCandidates; i++) {
            voteCounts.push(0);
        }
    }

    // NEW: The Delegation Function
    function delegate(address to) public {
        require(!hasVoted[msg.sender], "You already voted or delegated");
        require(to != msg.sender, "Cannot delegate to yourself");
        require(!hasVoted[to], "Cannot delegate to someone who already voted or delegated");

        // Mark the sender as having voted so they can't double-dip
        hasVoted[msg.sender] = true;
    
        // Add 1 to the chosen delegate's weight
        delegatedWeight[to] += 1;

        emit Delegated(msg.sender, to);
    }
    }

    // UPDATED: The Voting Function
    function vote(uint256 candidateId) public {
        require(!hasVoted[msg.sender], "You have already voted or delegated");
        require(candidateId < voteCounts.length, "Invalid candidate ID");

        hasVoted[msg.sender] = true;
        votedFor[msg.sender] = candidateId;

        // Calculate total weight: Their own 1 vote + any delegated votes they received
        uint256 totalWeight = 1 + delegatedWeight[msg.sender];
        
        voteCounts[candidateId] += totalWeight;

        emit Voted(msg.sender, candidateId, totalWeight);
    }

    function getAllResults() public view returns (uint256[] memory) {
        return voteCounts;
    }
}