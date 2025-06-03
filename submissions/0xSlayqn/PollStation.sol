// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


contract PollStation {


    string[] public candidateName;


    mapping(string => uint) public votes;


    function addcandidate(string memory _name) public  {
        candidateName.push(_name);
    }


    function castVote(string memory _candidateName) public {
        votes[_candidateName]++;
    }


    function getVoteCount(string memory _candidateName) public view returns(uint) {
        uint voteCount = votes[_candidateName];
        return voteCount;
    }
}
