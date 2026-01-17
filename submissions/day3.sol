// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{

    string[] public candidateNames;
    mapping(string => uint256) voteCount;
    mapping(address => bool) hasVoted;

    function addcandidateNames(string memory _candidateNames) public{
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
    }
    
    function getcandidateNames() public view returns (string[] memory){
        return candidateNames;
    }

    function vote(string memory _candidateNames) public{
        require(!hasVoted[msg.sender], "You have already voted!");
        hasVoted[msg.sender] = true;
        voteCount[_candidateNames] += 1;
    }

    function getVote(string memory _candidateNames) public view returns (uint256){
        return voteCount[_candidateNames];
    }

}
