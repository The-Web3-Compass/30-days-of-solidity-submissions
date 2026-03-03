// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    string[] public candidateNames;

    mapping(string => uint256) private voteCount;
    mapping(string => bool) public candidateExists; // To check if a candidate is registered
    mapping(address => bool) public hasVoted;

    function addCandidateNames(string memory _candidateNames) public {
        candidateNames.push(_candidateNames);
        voteCount [_candidateNames] = 0;
        candidateExists[_candidateNames] = true;
    }

    function getCandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }

    function vote(string memory _candidateNames) public {
        require(!hasVoted[msg.sender], "Nice try, you have already voted.");
        require(candidateExists[_candidateNames], "You may only vote for registered candidates.");
        voteCount [_candidateNames] += 1;
        hasVoted[msg.sender] = true;
    }

    function getVote(string memory _candidateNames) public view returns (uint256) {
        require(candidateExists[_candidateNames], "You may only vote for registered candidates.");
        return voteCount [_candidateNames];
    }
}