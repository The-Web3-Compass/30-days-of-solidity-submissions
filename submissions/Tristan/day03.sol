// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{

    string[] public candidateNames;
    mapping(string => uint256) voteCount;
    mapping (string=>bool) private nameexists;

    function addCandidateNames(string memory _candidateNames) public returns (string memory) {
        if(nameexists[_candidateNames]){
            return  "The person already exists";
        }
        candidateNames.push(_candidateNames);
        nameexists[_candidateNames] = true;
        voteCount[_candidateNames] = 0;
        return "Added successfully";
    }
    
    function getcandidateNames() public view returns (string[] memory){
        return candidateNames;
    }

    function vote(string memory _candidateNames) public returns(string memory){
        if(nameexists[_candidateNames]){
            voteCount[_candidateNames] += 1;
        return "voted successfully"; 
        }
        return "This person don't exists";
    }

    function getVote(string memory _candidateNames) public view returns (uint256){
        return voteCount[_candidateNames];
    }

}