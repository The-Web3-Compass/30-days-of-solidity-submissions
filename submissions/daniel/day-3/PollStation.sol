// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;
contract PollStation {

    string[] public candidatees;
    mapping(string => uint) public voteCount;
    mapping(address => string) public votes;

    function addCandidate(string memory _name) public {
        candidatees.push(_name);
    }

    function vote(string memory _candidate) public {
        voteCount[_candidate]++;
        votes[msg.sender] = _candidate;
    }
}
