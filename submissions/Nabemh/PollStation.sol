// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    // defining a candidate using structs
    struct Candidate {
        uint[] id;
        uint idVotes;
    }

    mapping(address => uint) public voter;
    Candidate[] public candidates; //array for all candidates

    function addCandidate(uint _id) public {
        Candidate storage newCandidate = candidates.push();
        newCandidate.id.push(_id);  // adding the id
        newCandidate.idVotes = 0;
    }

    function castVote(uint _i) public {
        candidates[_i].idVotes++;
    }

    function getVotes(uint _i) public view returns (uint) {
        return candidates[_i].idVotes; 
    }
}
