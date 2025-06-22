// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation{
    string[] public candidateNames;
    mapping(string => uint256) voteCount;
    mapping(string => bool) candidateExists;
    mapping(address => bool) voteState;

    function addCandidateNames(string memory _name) public {
        candidateNames.push(_name);
        candidateExists[_name]=true;
        voteCount[_name]=0;
    }

    function vote(string memory _name)public{
        require(!voteState[msg.sender],"Address has already voted");
        require(candidateExists[_name],"Candidate does not exist");

        voteCount[_name] += 1;
        voteState[msg.sender] = true;
    }

    function getCandidateNames()public view returns(string[] memory){
        return candidateNames;
    }

    function getVote(string memory _name)public view returns(uint256){
        require(candidateExists[_name],"Candidate does not exist");
        
        return voteCount[_name];
    }
}