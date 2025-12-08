// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{

    string[] public candidateNames;
    address[] public voterNames;
    mapping(string => uint256) voteCount;
    mapping(address => bool) voterStatus;

    function addCandidateNames(string memory _candidateNames) public{
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
    }
    
    function getcandidateNames() public view returns (string[] memory){
        return candidateNames;
    }

    function vote(string memory _candidateNames) public{
        voteCount[_candidateNames] += 1;
        voterNames.push(msg.sender);
        voterStatus[msg.sender] = true;
    }

    function getVote(string memory _candidateNames) public view returns (uint256){
        return voteCount[_candidateNames];
    }

    function getVoterStatus(address _voterAddress) public view returns (bool){
        return voterStatus[_voterAddress];
    }


}