// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PollStation {
    string[] public candidates;
    mapping(string => uint256) public votes;

    function addCandidate(string memory name) public {
        candidates.push(name);
    }

    function vote(string memory name) public returns (string memory) {
        votes[name] += 1;
        return "ok";
    }

    function getCandidates() public view returns (string[] memory) {
        return candidates;
    }

    function getVotes(string memory name) public view returns (uint256) {
        return votes[name];
    }
}