// SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

contract PollStation {
  
  string[] public candidateNames;
  mapping(string=>uint256) voteCount;

  function addCandidateNames(string memory _name) public {
    candidateNames.push(_name);
    voteCount[_name]=0
  }

  function getCandidateName() public view returns(string[])  {
    return candidateNames;
  }

  function voteCandidate(string memory _name) public{
    voteCount[_name]++;
  }

  function seeCandidate(string memory _name) public view returns(uint256) {
    return voteCount[_name];
  }
}