// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation{
    string[] public candidateNames;
    mapping(string => uint256) public voteCount;

    // check if address has voted
    mapping(address => bool) public hasVoted;
    // check if candidate exists
    mapping(string => bool) public isCandidate;

    function addCandidate(string memory _candidateNames) public {
        require(!isCandidate[_candidateNames], "Candidate already exists");
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
        isCandidate[_candidateNames] = true;
    }

    function vote(string memory _candidateNames) public {
        require(!hasVoted[msg.sender], "You have already voted");
        require(isCandidate[_candidateNames], "Candidate does not exist");
        voteCount[_candidateNames] += 1;
        hasVoted[msg.sender] = true;
    }

    function getCandidateNames() public view returns(string[] memory) {
        return candidateNames;
    }

    function getVote(string memory _candidateNames) public view returns(uint256) {
        return voteCount[_candidateNames];
    }
}