// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title VotingSystem
 * @author shivam
 * @notice Voting system with admin-controlled proposal creation and voter approval. Only approved users can vote, and each proposal tracks its vote count and voters.
 */
contract VotingSystem {
    /**
     * @notice Struct to store proposal details
     * @param name Name of the proposal
     * @param voteCount Number of votes received
     * @param hasVoted Mapping to track if an address has voted for this proposal
     */
    struct Proposal {
        string name;
        uint256 voteCount;
        mapping(address => bool) hasVoted;
    }

    /// @notice Address of contract owner (admin)
    address public owner;
    /// @notice List of all proposals
    Proposal[] private proposals;
    /// @notice Mapping of approved voter addresses
    mapping(address => bool) public approvedVoters;

    /// @notice Error thrown for unauthorized access (not owner or not approved)
    error NotAllowed();
    /// @notice Error thrown for invalid proposal index
    error InvalidProposal();
    /// @notice Error thrown for duplicate vote on a proposal
    error AlreadyVoted();

    /// @notice Event emitted when a new proposal is added
    /// @param proposalId Index of the proposal in the proposals array
    /// @param name Name of the proposal
    event ProposalAdded(uint256 indexed proposalId, string name);
    
    /// @notice Event emitted when a voter is approved
    /// @param voter Address approved to vote
    event VoterApproved(address indexed voter);

    /// @notice Event emitted when a vote is cast
    /// @param voter Address of the voter
    /// @param proposalId Index of the proposal voted for
    event Voted(address indexed voter, uint256 indexed proposalId);

    /// @notice Modifier to restrict function to contract owner
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotAllowed();
        _;
    }

    /// @notice Modifier to restrict function to approved voters
    modifier onlyApproved() {
        if (!approvedVoters[msg.sender]) revert NotAllowed();
        _;
    }

    /// @notice Initializes the contract by setting the owner to contract deployer
    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Add a new proposal
     * @param name Name of the proposal
     * @dev Only callable by owner
     */
    function addProposal(string calldata name) external onlyOwner {
        Proposal storage p = proposals.push();
        p.name = name;
        emit ProposalAdded(proposals.length - 1, name);
    }

    /**
     * @notice Approve a voter
     * @param voter Address to approve
     * @dev Only callable by owner
     */
    function approveVoter(address voter) external onlyOwner {
        approvedVoters[voter] = true;
        emit VoterApproved(voter);
    }

    /**
     * @notice Vote for a proposal (approved users only, one vote per proposal per user)
     * @param proposalId Index of the proposal (0-based)
     * @dev Emits Voted event on success
     * @custom:error InvalidProposal when proposalId is invalid
     * @custom:error AlreadyVoted when user has already voted for this proposal
     */
    function vote(uint256 proposalId) external onlyApproved {
        if (proposalId >= proposals.length) revert InvalidProposal();

        Proposal storage p = proposals[proposalId];
        if (p.hasVoted[msg.sender]) revert AlreadyVoted();
        
        p.hasVoted[msg.sender] = true;
        p.voteCount++;
        emit Voted(msg.sender, proposalId);
    }

    /**
     * @notice Get the total number of proposals
     * @return count Number of proposals
     */
    function proposalCount() external view returns (uint256 count) {
        return proposals.length;
    }

    /**
     * @notice Get proposal details by index
     * @param proposalId Index of the proposal
     * @return name Name of the proposal
     * @return voteCount Number of votes received
     */
    function getProposal(uint256 proposalId) external view returns (string memory name, uint256 voteCount) {
        if (proposalId >= proposals.length) revert InvalidProposal();
        Proposal storage p = proposals[proposalId];
        return (p.name, p.voteCount);
    }

    /**
     * @notice Check if a user has voted for a specific proposal
     * @param proposalId Index of the proposal
     * @param user Address to check
     * @return voted True if user has voted for proposal
     */
    function hasVoted(uint256 proposalId, address user) external view returns (bool voted) {
        if (proposalId >= proposals.length) revert InvalidProposal();
        return proposals[proposalId].hasVoted[user];
    }
}
