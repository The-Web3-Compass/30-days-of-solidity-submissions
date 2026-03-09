//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

contract PollStation{
    string[] public candidateNames;
    mapping(string => uint256) public vote;

    function addCandidates(string memory _candidateName) public {
        candidateNames.push(_candidateName);
        vote[_candidateName] = 0;
    }

    function getCandidateNames() public view returns (string[] memory){
        return candidateNames;
    }

    function voteToCandidate(string memory _candidateName) public {
        vote[_candidateName]++;
    }
    
    function voteCount(string memory _candidateName) public view returns (uint256){
        return vote[_candidateName];
    }
}