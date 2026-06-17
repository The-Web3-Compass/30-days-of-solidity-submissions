// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VotingPoll {
    struct Candidate {
        bytes32 name;  // Use bytes32 instead of string for gas efficiency
        uint256 voteCount;
    }

    address public immutable owner;
    uint256 public votingStart;
    uint256 public votingEnd;
    bool public isVotingOpen;

    Candidate[] private _candidates;
    mapping(bytes32 => uint256) private _candidateIndex;  // name hash => index
    mapping(address => bool) private _hasVoted;

    // --- Events ---
    event CandidateAdded(bytes32 name, uint256 index);
    event VoteCast(address voter, bytes32 candidate, uint256 newVoteCount);
    event VotingStatusChanged(bool isOpen);

    // --- Errors ---
    error Unauthorized();
    error VotingClosed();
    error AlreadyVoted();
    error CandidateNotFound();
    error DuplicateCandidate();
    error InvalidName();

    constructor(uint256 duration) {
        owner = msg.sender;
        votingStart = block.timestamp;
        votingEnd = votingStart + duration;
        isVotingOpen = true;
    }

    // --- External Functions ---

    function addCandidate(bytes32 name) external {
        if (msg.sender != owner) revert Unauthorized();
        if (!_isValidName(name)) revert InvalidName();
        if (_candidateIndex[name] != 0) revert DuplicateCandidate();

        _candidates.push(Candidate({name: name, voteCount: 0}));
        _candidateIndex[name] = _candidates.length;
        emit CandidateAdded(name, _candidates.length);
    }

    function vote(bytes32 candidateName) external {
        if (!isVotingOpen) revert VotingClosed();
        if (_hasVoted[msg.sender]) revert AlreadyVoted();

        uint256 candidateIndex = _candidateIndex[candidateName];
        if (candidateIndex == 0) revert CandidateNotFound();

        _candidates[candidateIndex - 1].voteCount++;
        _hasVoted[msg.sender] = true;
        emit VoteCast(msg.sender, candidateName, _candidates[candidateIndex - 1].voteCount);
    }

    function setVotingStatus(bool status) external {
        if (msg.sender != owner) revert Unauthorized();
        isVotingOpen = status;
        emit VotingStatusChanged(status);
    }

    // --- View Functions ---

    function getAllCandidates() external view returns (Candidate[] memory) {
        return _candidates;
    }

    function getVoteCount(bytes32 candidateName) external view returns (uint256) {
        uint256 candidateIndex = _candidateIndex[candidateName];
        if (candidateIndex == 0) revert CandidateNotFound();
        return _candidates[candidateIndex - 1].voteCount;
    }

    function hasVoted(address voter) external view returns (bool) {
        return _hasVoted[voter];
    }

    // --- Internal Functions ---

    function _isValidName(bytes32 name) internal pure returns (bool) {
        return name != 0x0;
    }
}