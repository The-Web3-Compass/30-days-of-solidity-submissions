// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{

    string[] public candidateNames;
    mapping(string => uint256) voteCount;

    function addCandidateNames(string memory _givecandidateNames) public{
        candidateNames.push(_givecandidateNames);
        voteCount[_givecandidateNames] = 0;
    }
    
    function getcandidateNames() public view returns (string[] memory){
        return candidateNames;
    }

    function vote(string memory _givecandidateNames) public{
        voteCount[_givecandidateNames] += 1;
    }

    function getVote(string memory _givecandidateNames) public view returns (uint256){
        return voteCount[_givecandidateNames];
    }

}