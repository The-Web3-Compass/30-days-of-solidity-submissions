// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title GasEfficientVoting
 * @notice Implements a voting system optimized for gas efficiency:
 *         - Uses compact types (uint8, uint32) and bytes32 instead of string.
 *         - Packs voter flags into a single uint256 per address using bitwise operations.
 */
contract GasEfficientVoting {
    // Number of proposals created (max 255)
    uint8 public proposalCount;

    /**
     * @dev Proposal details
     * @param name      Fixed-size bytes32 name to save gas vs string
     * @param voteCount Number of votes (uint32 supports up to 4.3B)
     * @param startTime Voting start timestamp (uint32 until year 2106)
     * @param endTime   Voting end timestamp
     * @param executed  Whether the proposal execution has occurred
     */
    struct Proposal {
        bytes32 name;
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }

    // Mapping from proposal ID to Proposal struct for O(1) lookups
    mapping(uint8 => Proposal) public proposals;

    /**
     * @dev Voter registry packed into a single uint256 per address
     *      Each bit represents if the voter has voted on a given proposal ID
     */
    mapping(address => uint256) private voterRegistry;

    // Tracks total number of unique voters per proposal for optional stats
    mapping(uint8 => uint32) public proposalVoterCount;

    // Events for creation, voting, and execution
    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    /**
     * @notice Create a new proposal with a duration
     * @param name     The proposal name (bytes32)
     * @param duration Voting duration in seconds (>0)
     */
    function createProposal(bytes32 name, uint32 duration) external {
        require(duration > 0, "Duration must be > 0");

        // Assign current count as new ID, then increment
        uint8 proposalId = proposalCount;
        proposalCount++;

        // Initialize and store new proposal
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
     * @notice Cast a vote for a proposal
     * @param proposalId The ID of the proposal to vote on
     */
    function vote(uint8 proposalId) external {
        // Validate proposal exists
        require(proposalId < proposalCount, "Invalid proposal");

        // Ensure within voting window
        uint32 nowTime = uint32(block.timestamp);
        Proposal storage p = proposals[proposalId];
        require(nowTime >= p.startTime, "Voting not started");
        require(nowTime <= p.endTime, "Voting ended");

        // Check if voter already voted on this proposal via bit mask
        uint256 mask = 1 << proposalId;
        require((voterRegistry[msg.sender] & mask) == 0, "Already voted");

        // Mark as voted and update counts
        voterRegistry[msg.sender] |= mask;
        p.voteCount++;
        proposalVoterCount[proposalId]++;

        emit Voted(msg.sender, proposalId);
    }

    /**
     * @notice Execute a proposal after voting ends
     * @param proposalId The ID of the proposal to execute
     */
    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        Proposal storage p = proposals[proposalId];
        require(block.timestamp > p.endTime, "Voting not ended");
        require(!p.executed, "Already executed");

        p.executed = true;
        emit ProposalExecuted(proposalId);
        // Execution logic would go here
    }

    /**
     * @notice Check if a voter has voted on a specific proposal
     * @param voter      Address of the voter
     * @param proposalId ID of the proposal
     * @return True if the voter has already voted
     */
    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        require(proposalId < proposalCount, "Invalid proposal");
        return (voterRegistry[voter] & (1 << proposalId)) != 0;
    }

    /**
     * @notice Retrieve full details for a proposal
     * @param proposalId ID of the proposal
     * @return name      bytes32 name
     * @return voteCount uint32 vote count
     * @return startTime uint32 start timestamp
     * @return endTime   uint32 end timestamp
     * @return executed  bool execution flag
     * @return active    bool whether current time is within voting window
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
        Proposal storage p = proposals[proposalId];
        return (
            p.name,
            p.voteCount,
            p.startTime,
            p.endTime,
            p.executed,
            block.timestamp >= p.startTime && block.timestamp <= p.endTime
        );
    }
}