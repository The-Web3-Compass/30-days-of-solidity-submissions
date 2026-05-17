// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


contract PollStation {
    string[] public candidateNames;
    mapping(string => uint256) voteCount;
    mapping(address => bool) hasVoting;
    mapping(string => bool) isRegistered;

    function addCandidateNames(string calldata _candidateNames) public{
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
        isRegistered[_candidateNames] = true;
        
    }
    
    function getcandidateNames() public view returns (string[] memory){
        return candidateNames;
    }

    function vote(string calldata _candidateNames) public{
        require(isRegistered[_candidateNames] == true, "Not a Candidate");
        require(!hasVoting[msg.sender],"Already Voted");
        hasVoting[msg.sender] = true;
        voteCount[_candidateNames] += 1;
    }

    function getVote(string calldata _candidateNames) public view returns (uint256){
        return voteCount[_candidateNames];
    }

}
