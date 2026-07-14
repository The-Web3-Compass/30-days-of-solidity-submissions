// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    string[] public candidateNames;
    mapping(string => uint256) private voteCount;
    mapping(address => bool) public hasVoted;
    mapping(string => bool) private candidateExists;

    function addCandidateNames(string memory _candidateNames) public {
        require(!candidateExists[_candidateNames], "Candidate already exists");
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
        candidateExists[_candidateNames] = true;
    }
    
    function getCandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }

    function vote(string memory _candidateNames) public {
        require(!hasVoted[msg.sender], "Already voted");
        require(candidateExists[_candidateNames], "Invalid candidate");
        
        voteCount[_candidateNames] += 1;
        hasVoted[msg.sender] = true;
    }

    function getVoteCount(string memory _candidateNames) public view returns (uint256) {
        require(candidateExists[_candidateNames], "Candidate doesn't exist");
        return voteCount[_candidateNames];
    }
}
