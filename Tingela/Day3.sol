// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract PollStation{


  string [ ] public candidateNames;

  mapping (string=>uint256)public voteCount;


  function addCandidate (string memory _candidateNames) public {
      candidateNames.push(_candidateNames);
      voteCount[_candidateNames]=0;

  }

  function vote (string memory _candidatedNames) public {
      voteCount[_candidateNames]++;

  }
  
