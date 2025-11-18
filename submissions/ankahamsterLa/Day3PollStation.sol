// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

// organize and structure data efficiently

contract PollStation{
    // declare array to store the names of candidate;
    // An array is a list of elements of the same type.
    string[] public candidateNames;
    // Mapping is like a dictionary that links a key to a value.
    mapping(string=>uint256) voteCount;

    // set function to add names of candidates and set the initial value of vote counts of candidate
    function addCandidateNames(string memory _candidateNames) public{
        //syntax: array_name.push(elements);
        //add new elements to the new array
        candidateNames.push(_candidateNames);
        //set intial value of vote counts of candidate in mapping structure
        voteCount[_candidateNames]=0;
    }
    //set function to return the string array of candidate's names
    function getcandidateNames() public view returns (string[] memory){
        return candidateNames;
    } 

    //set function to vote the candidate
    //In each vote, voting count plus one
    function vote(string memory _candidateNames) public{
        voteCount[_candidateNames]+=1;
    }

    //set function to get voting count's resluts from specific candidate in mapping structure
    function getVote(string memory _candidateNames) public view returns(uint256){
        return voteCount[_candidateNames];
    }




}