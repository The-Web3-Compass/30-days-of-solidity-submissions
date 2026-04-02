// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract PollStation {

    uint[] public votes;
    mapping(address=> uint) public votedFor;

    function addCandidate() public {
        votes.push(0);
    }

    function vote(uint _id) public {
        require(_id < votes.length, "Invalid candidate");
        require(votedFor[msg.sender] == 0, "Already Voted!");
        votedFor[msg.sender] = _id + 1;
        votes[_id]++;
    }

    function getVotes(uint _id) public view returns(uint) {
        require(_id < votes.length, "Invalid candidate");
        return votes[_id];
    }
}