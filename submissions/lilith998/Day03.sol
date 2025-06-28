// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollingStation {
    // Candidate structure
    struct Candidate {
        string name;
        uint voteCount;
    }
    
    // List of candidates
    Candidate[] public candidates;
    
    // Track who has voted
    mapping(address => bool) public hasVoted;
    
    // Track vote choices
    mapping(address => uint) public voteChoice;
    
    // Event for voting
    event Voted(address indexed voter, uint candidateIndex);
    
    // Initialize with default candidates
    constructor() {
        addCandidate("Alice");
        addCandidate("Bob");
        addCandidate("Charlie");
    }
    
    // Add a new candidate (only during deployment in this implementation)
    function addCandidate(string memory _name) private {
        candidates.push(Candidate({
            name: _name,
            voteCount: 0
        }));
    }
    
    // Vote for a candidate
    function vote(uint _candidateIndex) public {
        require(_candidateIndex < candidates.length, "Invalid candidate index");
        require(!hasVoted[msg.sender], "You have already voted");
        
        // Record the vote
        candidates[_candidateIndex].voteCount++;
        hasVoted[msg.sender] = true;
        voteChoice[msg.sender] = _candidateIndex;
        
        emit Voted(msg.sender, _candidateIndex);
    }
    
    // Get total number of candidates
    function getCandidateCount() public view returns (uint) {
        return candidates.length;
    }
    
    // Get total votes cast
    function getTotalVotes() public view returns (uint) {
        uint total = 0;
        for (uint i = 0; i < candidates.length; i++) {
            total += candidates[i].voteCount;
        }
        return total;
    }
    
    // Get election results
    function getResults() public view returns (string[] memory, uint[] memory) {
        string[] memory names = new string[](candidates.length);
        uint[] memory votes = new uint[](candidates.length);
        
        for (uint i = 0; i < candidates.length; i++) {
            names[i] = candidates[i].name;
            votes[i] = candidates[i].voteCount;
        }
        
        return (names, votes);
    }
}
