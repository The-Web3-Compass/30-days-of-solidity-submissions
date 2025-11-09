//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation {
    string[] public candidateNames;
    mapping(string => uint256) voteCounts; 

    function addCandidateNames(string memory _candidateName) public {
        candidateNames.push(_candidateName);
        voteCounts[_candidateName]++;
    }

    function getCandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }

    function vote(string memory _candidateName) public {
        voteCounts[_candidateName]++;
    }

    function getVote(string memory _candidateName) public view returns (uint256) {
        return voteCounts[_candidateName];
    } 
}
