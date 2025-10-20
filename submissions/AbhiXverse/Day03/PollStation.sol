// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

contract PollStation {

    // list of candidates 
    string[5] public CandidatesName = ["Abhi", "Ajax", "Rahul", "Modi", "Ashish"];

    // stores the vote count for each candidate 
    mapping (string => uint256) public voteCount;

    // tracks if the address has already voted 
    mapping(address => bool) public AlreadyVoted;

    // Total votes counts 
    uint256 public totalVotes;

    // function to vote for a candidate 
    function Vote(string memory _CandidatesName) public {
        require(!AlreadyVoted[msg.sender], "Cannot vote again");
        voteCount[_CandidatesName]++;
        AlreadyVoted[msg.sender] = true;
        totalVotes++;
    }
 
    // function to get the total votes 
    function getVoteCount(string memory _CandidatesName) public view returns (uint256) {
        return voteCount[_CandidatesName];   
    }

}



