// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title GasSaver - Gas-Efficient Voting System
 * @author Abhiram
 * @notice This contract demonstrates gas optimization techniques for a voting system
 * @dev Key optimizations:
 *      1. Using uint32 for counts and timestamps to pack storage
 *      2. Using calldata for function parameters to avoid memory copies
 *      3. Minimizing storage reads/writes with caching
 *      4. Bit-packing voter state in a single uint256
 *      5. Using events for non-critical data
 *      6. Avoiding redundant checks
 */
contract GasSaver {
    // =============================================================
    //                      STORAGE LAYOUT
    // =============================================================
    
    /**
     * @dev Proposal struct uses tight packing to minimize storage slots
     * All fields fit in 2 storage slots (32 bytes each):
     * Slot 1: proposer (20 bytes) + id (4 bytes) + endTime (4 bytes) + executed (1 byte)
     * Slot 2: yesVotes (32 bytes)
     * Slot 3: noVotes (32 bytes)
     */
    struct Proposal {
        address proposer;       // 20 bytes
        uint32 id;             // 4 bytes
        uint32 endTime;        // 4 bytes - Unix timestamp (safe until year 2106)
        bool executed;         // 1 byte
        uint256 yesVotes;      // 32 bytes - separate slot for vote counts
        uint256 noVotes;       // 32 bytes
    }
    
    // Owner of the contract
    address public immutable owner; // Using immutable saves gas vs storage
    
    // Proposal counter - uint32 supports 4.2 billion proposals
    uint32 public proposalCount;
    
    // Voting duration in seconds (e.g., 3 days = 259200)
    uint32 public immutable votingDuration;
    
    // Mapping from proposal ID to Proposal
    mapping(uint32 => Proposal) public proposals;
    
    /**
     * @dev Voter state packed into single uint256 for gas efficiency
     * We use bit manipulation to store vote info:
     * - Bit 0: Whether voted (1) or not (0)
     * - Bit 1: Vote choice - Yes (1) or No (0)
     * This allows us to check both voting status and choice in a single storage read
     */
    mapping(uint32 => mapping(address => uint256)) private voterState;
    
    // =============================================================
    //                          EVENTS
    // =============================================================
    
    /**
     * @dev Events are much cheaper than storage for historical data
     * Store proposal descriptions in events rather than storage
     */
    event ProposalCreated(
        uint32 indexed proposalId,
        address indexed proposer,
        string description,
        uint32 endTime
    );
    
    event Voted(
        uint32 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 weight
    );
    
    event ProposalExecuted(uint32 indexed proposalId, bool passed);
    
    // =============================================================
    //                        MODIFIERS
    // =============================================================
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    // =============================================================
    //                       CONSTRUCTOR
    // =============================================================
    
    /**
     * @param _votingDuration Duration in seconds for how long voting remains open
     */
    constructor(uint32 _votingDuration) {
        owner = msg.sender;
        votingDuration = _votingDuration;
    }
    
    // =============================================================
    //                    EXTERNAL FUNCTIONS
    // =============================================================
    
    /**
     * @notice Create a new proposal
     * @dev Uses calldata for description to avoid copying to memory
     * @param description Description of the proposal (stored in event, not storage)
     * @return proposalId The ID of the newly created proposal
     * 
     * Gas optimizations:
     * - Using calldata instead of memory saves ~2000 gas
     * - Storing description in event instead of storage saves ~20000 gas per character
     * - Using uint32 for timestamps and IDs
     */
    function createProposal(string calldata description) 
        external 
        returns (uint32 proposalId) 
    {
        // Cache to local variable to avoid multiple SLOAD operations
        uint32 currentCount = proposalCount;
        
        // Increment counter
        proposalId = ++currentCount;
        
        // Calculate end time
        uint32 endTime = uint32(block.timestamp) + votingDuration;
        
        // Create proposal - struct assignment is gas efficient
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            id: proposalId,
            endTime: endTime,
            executed: false,
            yesVotes: 0,
            noVotes: 0
        });
        
        // Update storage only once
        proposalCount = currentCount;
        
        // Emit event with description
        emit ProposalCreated(proposalId, msg.sender, description, endTime);
    }
    
    /**
     * @notice Vote on a proposal
     * @dev Optimized for minimal storage operations
     * @param proposalId ID of the proposal to vote on
     * @param support True for yes, false for no
     * 
     * Gas optimizations:
     * - Single storage read for proposal
     * - Bit-packed voter state
     * - Minimal storage writes
     * - Early returns to save gas on reverts
     */
    function vote(uint32 proposalId, bool support) external {
        // Load proposal into memory once (costs 1 SLOAD)
        Proposal storage proposal = proposals[proposalId];
        
        // Validation checks - fail fast to save gas
        require(proposal.endTime != 0, "Proposal does not exist");
        require(block.timestamp < proposal.endTime, "Voting ended");
        
        // Check if already voted (1 SLOAD)
        uint256 state = voterState[proposalId][msg.sender];
        require(state == 0, "Already voted");
        
        // For this simple version, each address gets 1 vote
        // In a more complex system, you could check token balances here
        uint256 weight = 1;
        
        // Update votes
        if (support) {
            proposal.yesVotes += weight;
        } else {
            proposal.noVotes += weight;
        }
        
        // Mark as voted with bit-packing:
        // Bit 0 = 1 (voted), Bit 1 = support (0 or 1)
        voterState[proposalId][msg.sender] = support ? 3 : 1; // 3 = 0b11, 1 = 0b01
        
        emit Voted(proposalId, msg.sender, support, weight);
    }
    
    /**
     * @notice Execute a proposal after voting ends
     * @dev Only owner can execute. In production, this could trigger other actions
     * @param proposalId ID of the proposal to execute
     * 
     * Gas optimizations:
     * - Caching storage reads
     * - Early validation
     */
    function executeProposal(uint32 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.endTime != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Already executed");
        
        // Mark as executed
        proposal.executed = true;
        
        // Check if proposal passed (yes > no)
        bool passed = proposal.yesVotes > proposal.noVotes;
        
        emit ProposalExecuted(proposalId, passed);
        
        // In a real system, you would execute the proposal action here
        // For example: calling another contract, transferring funds, etc.
    }
    
    /**
     * @notice Batch vote on multiple proposals
     * @dev More gas efficient than calling vote() multiple times
     * @param proposalIds Array of proposal IDs
     * @param voteSupports Array of vote choices (true for yes, false for no)
     * 
     * Gas optimizations:
     * - Using calldata for arrays (no memory copy)
     * - Batching operations
     * - Single function call overhead
     */
    function batchVote(
        uint32[] calldata proposalIds,
        bool[] calldata voteSupports
    ) external {
        require(proposalIds.length == voteSupports.length, "Length mismatch");
        
        uint256 length = proposalIds.length; // Cache length
        
        for (uint256 i; i < length;) {
            uint32 proposalId = proposalIds[i];
            bool support = voteSupports[i];
            
            Proposal storage proposal = proposals[proposalId];
            
            // Validation
            require(proposal.endTime != 0, "Proposal does not exist");
            require(block.timestamp < proposal.endTime, "Voting ended");
            
            uint256 state = voterState[proposalId][msg.sender];
            require(state == 0, "Already voted");
            
            uint256 weight = 1;
            
            if (support) {
                proposal.yesVotes += weight;
            } else {
                proposal.noVotes += weight;
            }
            
            voterState[proposalId][msg.sender] = support ? 3 : 1;
            
            emit Voted(proposalId, msg.sender, support, weight);
            
            // Unchecked increment saves gas (safe because array length is bounded)
            unchecked {
                ++i;
            }
        }
    }
    
    // =============================================================
    //                      VIEW FUNCTIONS
    // =============================================================
    
    /**
     * @notice Get proposal details
     * @param proposalId ID of the proposal
     * @return proposer Address of the proposer
     * @return endTime When voting ends
     * @return yesVotes Number of yes votes
     * @return noVotes Number of no votes
     * @return executed Whether the proposal has been executed
     */
    function getProposal(uint32 proposalId)
        external
        view
        returns (
            address proposer,
            uint32 endTime,
            uint256 yesVotes,
            uint256 noVotes,
            bool executed
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.endTime,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.executed
        );
    }
    
    /**
     * @notice Check if an address has voted on a proposal
     * @param proposalId ID of the proposal
     * @param voter Address to check
     * @return hasVoted Whether the address has voted
     * @return support The vote choice (only valid if hasVoted is true)
     */
    function getVoterInfo(uint32 proposalId, address voter)
        external
        view
        returns (bool hasVoted, bool support)
    {
        uint256 state = voterState[proposalId][voter];
        hasVoted = (state & 1) == 1; // Check bit 0
        support = (state & 2) == 2;  // Check bit 1
    }
    
    /**
     * @notice Get multiple proposal details at once
     * @dev More gas efficient for reading multiple proposals
     * @param proposalIds Array of proposal IDs to query
     * @return yesVotes Array of yes vote counts
     * @return noVotes Array of no vote counts
     * 
     * Gas optimization: Using calldata and returning arrays of primitive types
     */
    function getProposalsBatch(uint32[] calldata proposalIds)
        external
        view
        returns (
            uint256[] memory yesVotes,
            uint256[] memory noVotes
        )
    {
        uint256 length = proposalIds.length;
        yesVotes = new uint256[](length);
        noVotes = new uint256[](length);
        
        for (uint256 i; i < length;) {
            Proposal storage proposal = proposals[proposalIds[i]];
            yesVotes[i] = proposal.yesVotes;
            noVotes[i] = proposal.noVotes;
            
            unchecked {
                ++i;
            }
        }
    }
}