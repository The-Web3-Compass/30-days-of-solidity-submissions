// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract pollingStation {
    string[] public candidates;

    mapping(uint=>uint) public votes;
    mapping(address=>bool)public hasVoted;

     // Event for voting
    event Voted(address voter, uint candidateId);

    // Add candidates when deploying
    constructor(string[] memory _candidates) {
        candidates = _candidates;
    }

    // Vote for a candidate
    function vote(uint candidateId) public {
        require(candidateId < candidates.length, "Invalid candidate");
        require(!hasVoted[msg.sender], "You have already voted");

        votes[candidateId] += 1;
        hasVoted[msg.sender] = true;

        emit Voted(msg.sender, candidateId);
    }

    // Get total candidates
    function getCandidatesCount() public view returns (uint) {
        return candidates.length;
    }

    // Get candidate name and votes
    function getCandidate(uint candidateId) public view returns (string memory, uint) {
        require(candidateId < candidates.length, "Invalid candidate");
        return (candidates[candidateId], votes[candidateId]);
    }
}