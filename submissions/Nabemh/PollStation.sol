// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract PollStation{
    string[] public candidate;

    mapping (string => uint256) votes;

    function register(string memory _candidate) public {
        candidate.push(_candidate);
        votes[_candidate] = 0;
    }

    function vote(string memory _candidate) public {
        votes[_candidate]++;
    }

    function getCandidates() public view returns (string[] memory){
        return (candidate);
    }

    function getVotes(string memory _candidate) public view returns (uint256) {
        return (votes[_candidate]);
    }
}