//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract pollStation{

    string[] public candidatenames;
    mapping(string => uint256) voteCount;

    function addCandidateNames(string memory _candidateNames) public{
        candidatenames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
    }

    function getcandidateNames() public view returns (string[] memory){
        return candidatenames;
    }

    function vote(string memory _candidateNames) public{
        voteCount[_candidateNames] += 1;
    }

    function getVote(string memory _candidateNames) public view returns (uint256){
        return voteCount[_candidateNames];
    }

}