// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting {
    // support up to 255 proposals, smaller types save gas
    uint8 public proposalCount;

    // compact fields to reduce storage slots
    struct Proposal {
        bytes32 name;          // Use bytes32 instead of string to save gas
        uint32 voteCount;      // Supports up to ~4.3 billion votes
        uint32 startTime;      // Unix timestamp (supports dates until year 2106)
        uint32 endTime;        // Unix timestamp
        bool executed;         // Execution status
    }

    // proposals stored in mapping(uint8 => Proposal) for direct, more gas-efficient access.
    // Mapping avoids array growth costs and bounds checks on push
    mapping(uint8 => Proposal) public proposals;

    // Single-slot packed user data
    // Each address occupies one storage slot
    // Pack voter history into a single uint256 bitmap per address
    mapping(address => uint256) private voterRegistry;

    // Count total voters for each proposal (optional)
    mapping(uint8 => uint32) public proposalVoterCount;

    // indexed fields improve log filtering
    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    // === Core Functions ===
    
    /**
    * @dev Create a new proposal
    * @param name The proposal name (pass as bytes32 for gas efficiency)
    * @param duration Voting duration in seconds
    */
    function createProposal(bytes32 name, uint32 duration) external {
        require(duration > 0, "Duration must be > 0");
        
        // Increment counter - cheaper than .push() on an array
        uint8 proposalId = proposalCount;
        proposalCount++;
        
        // Use a memory struct and then assign to storage
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
    * @param proposalId The proposal ID
    */
    function vote(uint8 proposalId) external {
        // Require valid proposal
        require(proposalId < proposalCount, "Invalid proposal");
        
        // Check proposal voting period
        uint32 currentTime = uint32(block.timestamp);
        require(currentTime >= proposals[proposalId].startTime, "Voting not started");
        require(currentTime <= proposals[proposalId].endTime, "Voting ended");
        
        // Check if already voted using bit manipulation (gas efficient)
        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << proposalId;
        require((voterData & mask) == 0, "Already voted");
        
        // Record vote using bitwise OR
        voterRegistry[msg.sender] = voterData | mask;
        
        // Update proposal vote count
        proposals[proposalId].voteCount++;
        proposalVoterCount[proposalId]++;
        
        emit Voted(msg.sender, proposalId);
    }
    
    /**
    * @dev Execute a proposal after voting ends
    * @param proposalId The proposal ID
    */
    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        require(block.timestamp > proposals[proposalId].endTime, "Voting not ended");
        require(!proposals[proposalId].executed, "Already executed");
        
        proposals[proposalId].executed = true;
        
        emit ProposalExecuted(proposalId);
        
        // In a real contract, execution logic would happen here
    }
    
    // === View Functions ===
    
    /**
    * @dev Check if an address has voted for a proposal
    * @param voter The voter address
    * @param proposalId The proposal ID
    * @return True if the address has voted
    */
    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        return (voterRegistry[voter] & (1 << proposalId)) != 0;
    }
    
    /**
    * @dev Get detailed proposal information
    * Uses calldata for parameters and memory for return values
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
    * @dev Convert string to bytes32 (helper for frontend integration)
    * Note: This is a pure function that doesn't use state, so it's gas-efficient
    */

}