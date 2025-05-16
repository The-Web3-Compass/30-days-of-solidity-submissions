// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{
  string[] public candidates;
  mapping (string=>uint) public votes;
  mapping (address=>bool) public voted;

  function addCandidate(string memory _name) public{
    candidates.push(_name);
  }

  function vote(string memory _name) public{
    require(!voted[msg.sender])
    voted[msg.sender]=true;
    votes[_name]++;
  }
}
