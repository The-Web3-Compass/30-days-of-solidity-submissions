// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {

    // arrays storing list of candidates
    string[] public candidateNames;
    // creates a mapping to track voting for each candidates
    mapping (string => uint256) voteCount;

    // Mapping to track if an address has voted
    mapping (address => bool)  hasVoted;

    function addCandidatesNames(string memory _candidatesNames) public {
        candidateNames.push(_candidatesNames);
        voteCount[_candidatesNames] = 0;
    }

// 
    function getCandidateNames() public view returns (string[] memory)  {
        return candidateNames;
    }

    function vote(string memory _candidatesNames) public {
        require(!hasVoted[msg.sender], "You can only vote once");

        voteCount[_candidatesNames] += 1;
        hasVoted[msg.sender] = true;
    }

    function getVote(string memory _candidatesNames) public view returns (uint256){
        return voteCount[_candidatesNames];
    }


}
