// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollingStation {
    struct Candidate {
        string name;
        uint voteCount;
    }

    Candidate[] public candidates;

    mapping(address => bool) public hasVoted;

    event Voted(address indexed voter, uint candidateIndex);

    constructor(string[] memory _candidateNames) {
        for (uint i = 0; i < _candidateNames.length; i++) {
            candidates.push(Candidate({name: _candidateNames[i], voteCount: 0}));
        }
    }

    function vote(uint _candidateIndex) public {
        require(!hasVoted[msg.sender], "You have already voted!");
        require(_candidateIndex < candidates.length, "Invalid candidate!");

        hasVoted[msg.sender] = true;

        candidates[_candidateIndex].voteCount++;

        emit Voted(msg.sender, _candidateIndex);
    }

    function getCandidate(uint _index) public view returns (string memory, uint) {
        require(_index < candidates.length, "Invalid candidate index!");
        Candidate memory c = candidates[_index];
        return (c.name, c.voteCount);
    }

    function getTotalCandidates() public view returns (uint) {
        return candidates.length;
    }
}
