// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {

    struct Candidate {
        uint256 vote;
        bool exists;
    }

    string[] public candidateNames;
    mapping(string=>Candidate) public voteCount;
    mapping(address => bool) public hasVoted;

    

    function addCandidateName ( string memory _candidateName) public{
        candidateNames.push(_candidateName);
        voteCount[_candidateName] = Candidate(0, true);
    }

    function getCandidateNames () public view returns (string[] memory) {
        return candidateNames;
    }

    function addVote (string memory _candidateName) public {
        if(voteCount[_candidateName].exists && !hasVoted[msg.sender]) {
            voteCount[_candidateName].vote += 1;
            hasVoted[msg.sender] = true; 
        }
    }

    function getVotes (string memory _candidateName) public view returns (uint256) {
        return voteCount[_candidateName].vote;
    }

    function getAllVotes() public view returns (uint256[] memory) {
       uint256[] memory _votes = new uint256[](candidateNames.length);
       for(uint i = 0; i < candidateNames.length; i++) {
            _votes[i] = voteCount[candidateNames[i]].vote;
       }
       return _votes;
    }
}