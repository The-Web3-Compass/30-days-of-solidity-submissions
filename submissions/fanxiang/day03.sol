// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    string[] public candidateNames;
    mapping(string => uint256) public voteCounts;
    mapping(string => bool) public candidateExists;

    function addCandidate(string memory _name) public {
        candidateNames.push(_name);
        voteCounts[_name] = 0;
        candidateExists[_name] = true;
    }
    function vote(string memory _name) public {
        require(candidateExists[_name], "Candidate does not exist");
        voteCounts[_name]++;
    }
    function getCandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }
    function getVoteCounts(string memory _name) public view returns (uint256) {
        return voteCounts[_name];
    }
}