// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title PollStation
 * @author Nadiatus Salam
 * @notice A simple voting system where users can vote for candidates by ID.
 * @dev Solidity fundamentals exercise: Arrays (uint[]) and Mappings (address => uint).
 */
contract PollStation {

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    // Array of Candidate structs
    // Index 0 = Candidate 0, Index 1 = Candidate 1, etc.
    Candidate[] public candidates;

    // Mapping to track which candidate an address voted for
    // address => candidate ID
    mapping(address => uint256) public userVotedFor;
    
    // Mapping to check if an address has already voted
    mapping(address => bool) public hasVoted;

    // Events for transparency
    event Voted(address indexed voter, uint256 candidateId);
    event CandidateAdded(uint256 candidateId, string name);

    // Custom errors for gas efficiency
    error AlreadyVoted();
    error InvalidCandidateId();

    /**
     * @notice Adds a new candidate to the poll.
     * @param _name The name of the candidate.
     * @return candidateId The ID of the newly added candidate.
     */
    function addCandidate(string memory _name) external returns (uint256 candidateId) {
        candidates.push(Candidate({
            name: _name,
            voteCount: 0
        }));
        candidateId = candidates.length - 1;
        emit CandidateAdded(candidateId, _name);
    }

    /**
     * @notice Cast a vote for a specific candidate ID.
     * @dev Updates mappings and increments the candidate's vote count in the array.
     * @param _candidateId The ID of the candidate to vote for.
     */
    function vote(uint256 _candidateId) external {
        if (hasVoted[msg.sender]) revert AlreadyVoted();
        if (_candidateId >= candidates.length) revert InvalidCandidateId();

        // Record that the user has voted
        hasVoted[msg.sender] = true;
        
        // Record who they voted for
        userVotedFor[msg.sender] = _candidateId;

        // Increment the vote count for the candidate
        // Unchecked is safe here as vote count is unlikely to overflow uint256
        unchecked {
            candidates[_candidateId].voteCount++;
        }

        emit Voted(msg.sender, _candidateId);
    }

    /**
     * @notice Get the candidate details (name and vote count).
     * @param _candidateId The ID of the candidate.
     * @return name The candidate's name.
     * @return voteCount The candidate's total votes.
     */
    function getCandidate(uint256 _candidateId) external view returns (string memory name, uint256 voteCount) {
        if (_candidateId >= candidates.length) revert InvalidCandidateId();
        Candidate storage c = candidates[_candidateId];
        return (c.name, c.voteCount);
    }

    /**
     * @notice Get the total number of candidates.
     * @return The length of the candidates array.
     */
    function getTotalCandidates() external view returns (uint256) {
        return candidates.length;
    }
}