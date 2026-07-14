// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{

    string[] public candidateNames;
    mapping(string => uint256) private voteCount;
    mapping(string => bool) private candidateExists;

    function addCandidateNames(string memory _candidateNames) public{
        require(!candidateExists[_candidateNames], "Candidate already exists.");
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
        candidateExists[_candidateNames] = true;
    }
    
    function getcandidateNames() public view returns (string[] memory){
        return candidateNames;
    }

    function vote(string memory _candidateNames) public{
        require(candidateExists[_candidateNames], "Candidate does not exist.");
        voteCount[_candidateNames] += 1;
    }

    function getVote(string memory _candidateNames) public view returns (uint256){
        require(candidateExists[_candidateNames], "Candidate does not exist.");
        return voteCount[_candidateNames];
    }

}