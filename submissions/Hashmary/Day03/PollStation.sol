/*---------------------------------------------------------------------------
  File:   PollStation.sol
  Author: Marion Bohr
  Date:   04/03/2025
  Description:
    Let's build a simple polling station! Users will be able to vote for 
    their favorite candidates. You'll use lists (arrays, `uint[]`) to store 
    candidate details. You'll also create a system (mappings, 
    `mapping(address => uint)`) to remember who (their `address`) voted for 
    which candidate. Think of it as a digital voting booth. This teaches you 
    how to manage data in a structured way.
----------------------------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract PollStation {
    // Candidate structure
    struct Candidate {
        string name;
        uint voteCount;
    }

    // List of all candidates
    Candidate[] public candidates;

    // Track if an address has already voted
    mapping(address => bool) public hasVoted;

    // Add a new candidate by name
    function addCandidate(string memory _name) public {
        candidates.push(Candidate({
            name: _name,
            voteCount: 0
        }));
    }

    // Get all candidate names
    function getCandidateNames() public view returns (string[] memory) {
        string[] memory names = new string[](candidates.length);
        for (uint i = 0; i < candidates.length; i++) {
            names[i] = candidates[i].name;
        }
        return names;
    }

    // Vote for a candidate by name
    function vote(string memory _name) public {
        require(!hasVoted[msg.sender], "Already voted.");
        for (uint i = 0; i < candidates.length; i++) {
            if (keccak256(bytes(candidates[i].name)) == keccak256(bytes(_name))) {
                candidates[i].voteCount += 1;
                hasVoted[msg.sender] = true;
                return;
            }
        }
        revert("Candidate not found.");
    }

    // Get vote count for a candidate by name
    function getVotes(string memory _name) public view returns (uint) {
        for (uint i = 0; i < candidates.length; i++) {
            if (keccak256(bytes(candidates[i].name)) == keccak256(bytes(_name))) {
                return candidates[i].voteCount;
            }
        }
        revert("Candidate not found.");
    }
}