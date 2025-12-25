//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{
  
  string[]public candidateNames;
  mapping(string =>uint) voteCount;

  function addCandidateNames(string memory _candidateNames) public{
    candidateNames.push(_candidateNames);
    voteCount[_candidateNames];
    }// initialize the count to be 0, use [] because it's a mapping not a function, which is similar to a lookup in excel
  
  function getCandidateNames() public view returns (string[] memory){
    return candidateNames;
    }
  function vote(string memory _candidateNames) public {
    voteCount[_candidateNames] +=1;
    }
  function getVote(string memory _candidateNames) public view returns (uint256) {
    return voteCount[_candidateNames];
  }
}
