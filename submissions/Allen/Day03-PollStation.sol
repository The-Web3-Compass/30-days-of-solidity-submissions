// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

contract PollStation{

     
    string[] public candidateNames;
    mapping(string => uint256) voteCount;


    function addCandidateNames(string memory _candidateNames) public {
        candidateNames.push(_candidateNames);
         voteCount[_candidateNames] = 0;
    }

    function getCandidateNames() public view returns(string[] memory){
        return candidateNames;
    }

    function vote(string memory _candidateName) public{
        // A real-world implementation should prevent duplicate voting
        // If this candidate doesn't exist, this operation doesn't work.
        voteCount[_candidateName] += 1;
    }

    function getVote(string memory _candidateName) public view returns(uint256){
        return voteCount[_candidateName];

    }


}