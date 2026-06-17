// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    string[] public candidates;                  
    mapping(address => uint) public votes;       
    mapping(string => uint) public voteCount;    

    // Add candidates at deployment
    constructor(string[] memory _candidates) {
        candidates = _candidates;
    }

    // Vote for a candidate by index
    function vote(uint candidateIndex) public {
        require(candidateIndex < candidates.length, "Invalid candidate");
        require(votes[msg.sender] == 0, "You already voted");

        string memory chosen = candidates[candidateIndex];
        votes[msg.sender] = candidateIndex + 1; 
        voteCount[chosen]++;
    }

    
    function getVotes(string memory candidate) public view returns (uint) {
        return voteCount[candidate];
    }
}
