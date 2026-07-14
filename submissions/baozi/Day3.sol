// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {

    string[] public candidateNames;
    mapping(string => uint256) private voteCount;
    mapping(string => bool) private candidateExists;

    function addCandidate(string memory _candidateName) public {
        require(!candidateExists[_candidateName], "Candidate already exists.");
        candidateNames.push(_candidateName);
        candidateExists[_candidateName] = true;
        voteCount[_candidateName] = 0;
    }

    function getCandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }

    function vote(string memory _candidateName) public {
        require(candidateExists[_candidateName], "Candidate does not exist.");
        voteCount[_candidateName] += 1;
    }

    function getVote(string memory _candidateName) public view returns (uint256) {
        require(candidateExists[_candidateName], "Candidate does not exist.");
        return voteCount[_candidateName];
    }
}
