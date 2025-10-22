// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    string[] public candidateNames;
    mapping(string => uint256) public voteCount;

    function addCandidateNames(string memory _candidateName) public {
        candidateNames.push(_candidateName);
        voteCount[_candidateName] = 0;
    }

    function getCandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }

    function vote(string memory _candidateName) public {
        voteCount[_candidateName] += 1;
    }

    function getVote(string memory _candidateName) public view returns (uint256) {
        return voteCount[_candidateName];  // Fixed: Changed __candidateNames → _candidateName
    }
}