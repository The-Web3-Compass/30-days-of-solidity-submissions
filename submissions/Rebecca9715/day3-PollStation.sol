// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract PollStation {
    string[] public candidateNames;
    mapping(string => uint256) voteCount;

    function addCandidate(string memory _candidateNames) public{
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
    }


    function vote(string memory _candidateNames) public{
        voteCount[_candidateNames] += 1;
    }

    function getCandidateNames() external view returns (string[] memory) {
        return candidateNames;
    }

    function getVote(string memory _candidateNames) external view returns (uint) {
        return voteCount[_candidateNames];
    }
}
