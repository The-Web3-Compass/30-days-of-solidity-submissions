// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract PollStation{
    string[] public candidateNames;
    mapping(string => uint256) voteCount;

    // check if candidate exisits
    mapping(string => bool) private isCandidate;

    // check if address exists
    mapping(address => bool) private hasVoted;

    function addCandidateNames(string memory _candidateNames)public{
        candidateNames.push(_candidateNames);
        isCandidate[_candidateNames] = true;
        voteCount[_candidateNames] = 0;
    }
    function getcandidateNames() public view returns (string[]memory){
        return candidateNames;
    }
    function vote(string memory _candidateNames)public{
        require(!hasVoted[msg.sender], "You have already voted");
        require(isCandidate[_candidateNames], "Candidate does not exist");
        voteCount[_candidateNames] += 1;
        hasVoted[msg.sender] = true;
    }

    function getVote(string memory _candidateNames) public  view returns (uint256){
        return voteCount[_candidateNames];
    }
}