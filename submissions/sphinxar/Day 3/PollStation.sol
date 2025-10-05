// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract PollStation {
    string[] public candidates;
    mapping (address => uint256) public votes;

    constructor () {}

    function setCandidate(string memory name) public {
        candidates.push(name);
    }

    function vote(uint256 candidateId) public {
        votes[msg.sender] = candidateId;
    }
}
