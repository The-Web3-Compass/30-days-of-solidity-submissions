// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Pollstaion{

    string[] candidateNames;
    //a dynamic array of strings which will store candidate names
    mapping(string => uint256) voteCount;
    //a mapping which will store vote count for each candidate name inputted

    function addCandidateNames(string memory i_candidateNames) public{
        candidateNames.push(i_candidateNames);
        //append each inputted candidate name to the array
        voteCount[i_candidateNames] = 0;
        //store vote count as zero for each inputted candidate name
    }

    function vote(string memory i_candidateNames) public{
        voteCount[i_candidateNames] += 1;// vote for the inputted candidate by +1 vote count
    }

    function getCandidateNames() public view returns (string[] memory){
        return candidateNames;
    }

    function getVote(string memory _candidateNames) public view returns (uint256){
        return voteCount[_candidateNames];
    }

}