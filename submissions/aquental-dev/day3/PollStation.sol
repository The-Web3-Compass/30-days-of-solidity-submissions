// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollingStation {
    // Structure to represent a candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Array to store all candidates
    Candidate[] public candidates;

    // Mapping to track which candidate each address voted for
    // 0 means hasn't voted, candidate IDs start from 1
    mapping(address => uint) public voterToCandidate;

    // Mapping to check if an address has already voted
    mapping(address => bool) public hasVoted;

    // Owner of the contract (who can add candidates)
    address public owner;

    // Events
    event CandidateAdded(uint candidateId, string name);
    event VoteCast(address voter, uint candidateId, string candidateName);

    // Modifier to restrict access to owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // Function to add a new candidate (only owner)
    function addCandidate(string memory _name) public onlyOwner {
        uint candidateId = candidates.length + 1;
        candidates.push(Candidate(candidateId, _name, 0));
        emit CandidateAdded(candidateId, _name);
    }

    // Function to vote for a candidate
    function vote(uint _candidateId) public {
        // Check if voter has already voted
        require(!hasVoted[msg.sender], "You have already voted");

        // Check if candidate ID is valid
        require(
            _candidateId > 0 && _candidateId <= candidates.length,
            "Invalid candidate ID"
        );

        // Record the vote
        voterToCandidate[msg.sender] = _candidateId;
        hasVoted[msg.sender] = true;

        // Increment candidate's vote count
        candidates[_candidateId - 1].voteCount++;

        // Emit vote event
        emit VoteCast(
            msg.sender,
            _candidateId,
            candidates[_candidateId - 1].name
        );
    }

    // Function to get candidate details by ID
    function getCandidate(
        uint _candidateId
    ) public view returns (uint, string memory, uint) {
        require(
            _candidateId > 0 && _candidateId <= candidates.length,
            "Invalid candidate ID"
        );
        Candidate memory candidate = candidates[_candidateId - 1];
        return (candidate.id, candidate.name, candidate.voteCount);
    }

    // Function to get all candidates
    function getAllCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    // Function to get total number of candidates
    function getCandidateCount() public view returns (uint) {
        return candidates.length;
    }

    // Function to check who a specific address voted for
    function getVoteOf(
        address _voter
    ) public view returns (uint, string memory) {
        require(hasVoted[_voter], "This address hasn't voted yet");
        uint candidateId = voterToCandidate[_voter];
        return (candidateId, candidates[candidateId - 1].name);
    }

    // Function to get the winning candidate
    function getWinner() public view returns (uint, string memory, uint) {
        require(candidates.length > 0, "No candidates available");

        uint winningVoteCount = 0;
        uint winningCandidateId = 0;

        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateId = candidates[i].id;
            }
        }

        require(winningCandidateId > 0, "No votes cast yet");
        Candidate memory winner = candidates[winningCandidateId - 1];
        return (winner.id, winner.name, winner.voteCount);
    }

    // Function to get total votes cast
    function getTotalVotes() public view returns (uint) {
        uint totalVotes = 0;
        for (uint i = 0; i < candidates.length; i++) {
            totalVotes += candidates[i].voteCount;
        }
        return totalVotes;
    }
}
