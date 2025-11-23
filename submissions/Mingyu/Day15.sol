// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting {

    uint8 public proposalCount;

    struct Proposal {
        bytes32 name;           // Use bytes32 instead of string for gas savings
        uint32 voteCount;       // Reduced to uint32 (enough for typical votes)
        uint32 startTime;       // Start time
        uint32 endTime;         // End time
        bool executed;          // Execution status
    }

    // Proposal mapping
    mapping(uint8 => Proposal) public proposals;

    // Bitmap storage for voter history (1 bit per proposal)
    mapping(address => uint256) private voterRegistry;

    // Mapping for tracking the number of voters in each proposal
    mapping(uint8 => uint32) public proposalVoterCount;

    // Events for transparency
    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    // === Core Functions ===

    /**
     * @dev Create a new proposal
     * @param name Proposal name (bytes32 for gas efficiency)
     * @param duration Voting duration in seconds
     */
    function createProposal(bytes32 name, uint32 duration) external {
        require(duration > 0, "Duration must be > 0");

        uint8 proposalId = proposalCount;
        proposalCount++;

        // Use memory struct and assign to storage
        Proposal memory newProposal = Proposal({
            name: name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + duration,
            executed: false
        });

        proposals[proposalId] = newProposal;

        emit ProposalCreated(proposalId, name);
    }

    /**
     * @dev Vote on a proposal
     * @param proposalId Proposal ID to vote on
     */
    function vote(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");

        uint32 currentTime = uint32(block.timestamp);
        require(currentTime >= proposals[proposalId].startTime, "Voting not started");
        require(currentTime <= proposals[proposalId].endTime, "Voting ended");

        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << proposalId;
        require((voterData & mask) == 0, "Already voted");

        // Record vote using bitwise OR operation
        voterRegistry[msg.sender] = voterData | mask;

        // Update proposal vote count
        proposals[proposalId].voteCount++;
        proposalVoterCount[proposalId]++;

        emit Voted(msg.sender, proposalId);
    }

    /**
     * @dev Execute a proposal after voting ends
     * @param proposalId Proposal ID to execute
     */
    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        require(block.timestamp > proposals[proposalId].endTime, "Voting not ended");
        require(!proposals[proposalId].executed, "Already executed");

        proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);
        // Additional logic for executing the proposal could go here
    }

    // === View Functions ===

    /**
     * @dev Check if an address has voted for a specific proposal
     * @param voter Address of the voter
     * @param proposalId Proposal ID
     * @return True if the address has voted for the proposal
     */
    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        return (voterRegistry[voter] & (1 << proposalId)) != 0;
    }

    /**
     * @dev Get detailed proposal information
     * @param proposalId Proposal ID
     * @return Name, vote count, start time, end time, execution status, and whether the proposal is active
     */
    function getProposal(uint8 proposalId) external view returns (
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool executed,
        bool active
    ) {
        require(proposalId < proposalCount, "Invalid proposal");

        Proposal storage proposal = proposals[proposalId];

        return (
            proposal.name,
            proposal.voteCount,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            (block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime)
        );
    }

    /**
     * @dev Helper function to convert string to bytes32 (for frontend integration)
     * @param str String to convert
     * @return Resulting bytes32 representation
     */
    function stringToBytes32(string memory str) external pure returns (bytes32) {
        return bytes32(keccak256(abi.encodePacked(str)));
    }
}
