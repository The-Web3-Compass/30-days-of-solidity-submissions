// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title PollStation - A Simple Voting Contract
/// @author 
/// @notice This contract lets users vote for their favorite candidates.
/// @dev Demonstrates arrays, mappings, and basic voting logic.
contract PollStation {
    // 🔹 Candidate list (indexed by candidateId)
    string[] public candidates;

    // 🔹 Votes received by candidateId
    mapping(uint => uint) public votes;

    // 🔹 Track who has voted already
    mapping(address => bool) public hasVoted;

    // 🔹 Track which candidate a voter selected
    mapping(address => uint) public votedFor;

    // 🔹 Event logs (so frontend or etherscan can listen)
    event CandidateAdded(uint candidateId, string name);
    event Voted(address voter, uint candidateId);

    /// @notice Add a new candidate
    /// @param _name Name of the candidate
    function addCandidate(string memory _name) external {
        candidates.push(_name);
        emit CandidateAdded(candidates.length - 1, _name);
    }

    /// @notice Vote for a candidate
    /// @param candidateId ID of the candidate (0-based index)
    function vote(uint candidateId) external {
        require(candidateId < candidates.length, "Invalid candidate");
        require(!hasVoted[msg.sender], "Already voted");

        votes[candidateId] += 1;
        hasVoted[msg.sender] = true;
        votedFor[msg.sender] = candidateId;

        emit Voted(msg.sender, candidateId);
    }

    /// @notice Get total votes for a candidate
    function getVotes(uint candidateId) external view returns (uint) {
        require(candidateId < candidates.length, "Invalid candidate");
        return votes[candidateId];
    }

    /// @notice Get candidate count
    function getCandidateCount() external view returns (uint) {
        return candidates.length;
    }

    /// @notice See which candidate an address voted for
    function whoVotedFor(address _voter) external view returns (string memory) {
        require(hasVoted[_voter], "This address has not voted yet");
        return candidates[votedFor[_voter]];
    }
}
