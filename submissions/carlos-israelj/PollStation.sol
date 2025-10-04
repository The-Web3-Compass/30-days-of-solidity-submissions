// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.26;

/**
 * @title PollStation
 * @author Carlos I Jimenez
 * @notice A simple voting contract for casting votes for candidates
 * @dev Implements basic polling functionality with vote tracking
 */
contract PollStation {
    
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Array storing vote counts for each candidate
    /// @dev Index represents candidate ID, value represents vote count
    uint256[] public s_votes;
    
    /// @notice Mapping to track which candidate each address voted for
    /// @dev Maps voter address to candidate ID (0 means hasn't voted)
    mapping(address => uint256) public s_voterToCandidate;
    
    /// @notice Mapping to track if an address has voted
    /// @dev Maps voter address to boolean (true if voted, false otherwise)
    mapping(address => bool) public s_hasVoted;
    
    /// @notice Total number of votes cast
    uint256 public s_totalVotes;
    
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Emitted when a vote is cast
    /// @param voter The address of the voter
    /// @param candidateId The ID of the candidate voted for
    event VoteCast(address indexed voter, uint256 indexed candidateId);
    
    /// @notice Emitted when a new candidate is added
    /// @param candidateId The ID of the new candidate
    event CandidateAdded(uint256 indexed candidateId);
    
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Thrown when a user tries to vote twice
    error PollStation__AlreadyVoted();
    
    /// @notice Thrown when voting for an invalid candidate ID
    error PollStation__InvalidCandidate();
    
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Initializes the poll with a specified number of candidates
     * @dev Creates an array with initial vote counts of 0 for each candidate
     * @param _numberOfCandidates The number of candidates in the poll
     */
    constructor(uint256 _numberOfCandidates) {
        s_votes = new uint256[](_numberOfCandidates);
    }
    
    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Cast a vote for a candidate
     * @dev Records the vote and prevents double voting
     * @param _candidateId The ID of the candidate (0-indexed)
     */
    function vote(uint256 _candidateId) external {
        if (s_hasVoted[msg.sender]) {
            revert PollStation__AlreadyVoted();
        }
        
        if (_candidateId >= s_votes.length) {
            revert PollStation__InvalidCandidate();
        }
        
        s_votes[_candidateId]++;
        s_voterToCandidate[msg.sender] = _candidateId;
        s_hasVoted[msg.sender] = true;
        s_totalVotes++;
        
        emit VoteCast(msg.sender, _candidateId);
    }
    
    /**
     * @notice Adds a new candidate to the poll
     * @dev Increases the array size by one and initializes vote count to 0
     */
    function addCandidate() external {
        s_votes.push(0);
        emit CandidateAdded(s_votes.length - 1);
    }
    
    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Get the vote count for a specific candidate
     * @param _candidateId The ID of the candidate
     * @return The number of votes the candidate has received
     */
    function getVotes(uint256 _candidateId) external view returns (uint256) {
        if (_candidateId >= s_votes.length) {
            revert PollStation__InvalidCandidate();
        }
        return s_votes[_candidateId];
    }
    
    /**
     * @notice Get all vote counts
     * @return Array containing vote counts for all candidates
     */
    function getAllVotes() external view returns (uint256[] memory) {
        return s_votes;
    }
    
    /**
     * @notice Get the total number of candidates
     * @return The number of candidates in the poll
     */
    function getCandidateCount() external view returns (uint256) {
        return s_votes.length;
    }
    
    /**
     * @notice Check which candidate an address voted for
     * @param _voter The address to check
     * @return The candidate ID the voter voted for (0 if hasn't voted)
     */
    function getVoterChoice(address _voter) external view returns (uint256) {
        return s_voterToCandidate[_voter];
    }
    
    /**
     * @notice Check if an address has voted
     * @param _voter The address to check
     * @return True if the address has voted, false otherwise
     */
    function hasVoted(address _voter) external view returns (bool) {
        return s_hasVoted[_voter];
    }
    
    /**
     * @notice Get the candidate with the most votes
     * @return winningCandidateId The ID of the winning candidate
     * @return winningVoteCount The number of votes the winner has
     */
    function getWinner() external view returns (uint256 winningCandidateId, uint256 winningVoteCount) {
        winningVoteCount = 0;
        winningCandidateId = 0;
        
        for (uint256 i = 0; i < s_votes.length; i++) {
            if (s_votes[i] > winningVoteCount) {
                winningVoteCount = s_votes[i];
                winningCandidateId = i;
            }
        }
        
        return (winningCandidateId, winningVoteCount);
    }
}