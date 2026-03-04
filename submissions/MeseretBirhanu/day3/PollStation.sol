// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PollStation{

    struct Candidate{
        string name;
        uint32 id;
        uint32 votes;
    }

    uint32 public totalCandidtes;
    mapping (uint32 => Candidate) public currentCandidates;
    mapping(address=>Candidate)public userVotes;
    mapping(address => bool) public hasVoted;

    address[] public voters; 

   function registerforCandidate(string memory _name) public{
    totalCandidtes++;
   currentCandidates[totalCandidtes] = Candidate(_name, totalCandidtes,0);
   }

   //vote by ID
   function vote(uint32 _id)public{
    require(!hasVoted[msg.sender],"You already voted");
    require(_id>0 && _id<=totalCandidtes,"invalid candidate id");
    userVotes[msg.sender] = currentCandidates[_id];
    currentCandidates[_id].votes++;
    hasVoted[msg.sender]=true;
     voters.push(msg.sender);
   }
}