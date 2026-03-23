// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error PollStation__UserHasVotedBefore(address voter);
error PollStation__NonValidCandidateIndex(uint256 index);
error PollStation__NonValidVoterAddress(address voter);
error PollStation__NotAuthorized();

contract PollStation {
    struct Candidate {
        string name;
        uint256 votes;
    }

    uint256 totalVotes;
    address private immutable OWNER;

    Candidate[] candidates;
    mapping(address => string) userVotedCandidate;
    mapping(address => bool) hasVoted;

    event UserVoted(address voter, string candidate);

    modifier hasVotedBefore(address _voter) {
        if (hasVoted[_voter]) revert PollStation__UserHasVotedBefore(_voter);
        _;
    }

    modifier checkIndex(uint256 _index) {
        if (_index >= candidates.length) revert PollStation__NonValidCandidateIndex(_index);
        _;
    }

    modifier onlyOwner() {
        if (OWNER != msg.sender) revert PollStation__NotAuthorized();
        _;
    }

    constructor() {
        OWNER = msg.sender;
    }

    function voteByIndex(uint256 _index) external checkIndex(_index) hasVotedBefore(msg.sender) {
        address voter = msg.sender;
        hasVoted[voter] = true;
        string memory candidateName = candidates[_index].name;
        userVotedCandidate[voter] = candidateName;
        candidates[_index].votes++;
        totalVotes++;
        emit UserVoted(voter, candidateName);
    }

    function getCandidateTotalVotesByIndex(uint256 _index) external view checkIndex(_index) returns (uint256) {
        Candidate memory candidate = candidates[_index];
        return candidate.votes;
    }

    function getCandidateName(uint256 _index) external view checkIndex(_index) returns (string memory) {
        Candidate memory candidate = candidates[_index];
        return candidate.name;
    }

    function getCandidatesNames() external view returns (string[] memory) {
        string[] memory candidatesNames = new string[](candidates.length);
        for (uint256 i = 0; i < candidates.length; i++) {
            candidatesNames[i] = candidates[i].name;
        }
        return candidatesNames;
    }

    function getVoterCandidate(address _voter) external view returns (string memory) {
        if (_voter == address(0)) revert PollStation__NonValidVoterAddress(_voter);
        if (!hasVoted[_voter]) revert PollStation__NonValidVoterAddress(_voter);
        return userVotedCandidate[_voter];
    }

    function getTotalVotes() external view returns (uint256) {
        return totalVotes;
    }

    function addCandidate(string memory _candidate) external onlyOwner {
        bytes32 candidateHash = keccak256(bytes(_candidate));
        for (uint256 i = 0; i < candidates.length; i++) {
            require(keccak256(bytes(candidates[i].name)) != candidateHash, "Candidate already exists");
        }
        candidates.push(Candidate({name: _candidate, votes: 0}));
}
