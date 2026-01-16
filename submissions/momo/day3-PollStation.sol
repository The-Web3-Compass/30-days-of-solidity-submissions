//SPDX-License-Idntifier:MIT
pragma solidity ^0.8.0;

contract PollStation {
  string [] public candidateNames;
  mapping(string => uint256) voteCount;
  mapping(address => bool) hasVoted;
  
  function addCandidateNames(string memory _candidateName) {
    candidateNames.push("_candidateName");
    voteCount["_candidateName"] = 0;
  }

  function getCandidateNames() public view returns(string memory[]) {
    return candidateNames;
  }

  function vote(string memory _candidateName) public {
    require(!hasVoted[msg.sender]);
    voteCount[_candidateName] += 1;

    hasVoted[msg.sender] = true;
  }

  function getVote(string memory _candidateName) public view returns(uint256){
    return voteCount[_candidateName];
  }
}
