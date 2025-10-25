// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {

    string[] public candidateNames;
    mapping(string => uint256) public voteCount; 
    mapping(address => bool) public hasVoted;

    function addCandidateNames(string memory _candidateNames) public {
        for (uint256 i = 0; i < candidateNames.length; i++) {
            if (keccak256(bytes(candidateNames[i])) == keccak256(bytes(_candidateNames))) {
                revert("Candidate already exists");
            }
        }

        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
    }

    function getCandidateNames() public view returns (string[] memory) { 
        return candidateNames;
    }

    function vote(string memory _candidateNames) public {
        require(!hasVoted[msg.sender], "You have already voted!");

        bool candidateExists = false;
        for (uint256 i = 0; i < candidateNames.length; i++) {
            if (keccak256(bytes(candidateNames[i])) == keccak256(bytes(_candidateNames))) {
                candidateExists = true;
                break;
            }
        }
        require(candidateExists, "Candidate does not exist!");

        voteCount[_candidateNames] += 1;
        hasVoted[msg.sender] = true;
    }

    function getVote(string memory _candidateNames) public view returns (uint256) {
        return voteCount[_candidateNames];
    }
}
