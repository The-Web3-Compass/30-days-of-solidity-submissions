// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title UnoptimizedVoting
 * @notice This is an UNOPTIMIZED version for comparison purposes
 * @dev This contract intentionally uses gas-inefficient patterns to demonstrate
 *      the improvements made in GasSaver.sol
 * 
 * DO NOT USE THIS IN PRODUCTION - FOR EDUCATIONAL PURPOSES ONLY
 */
contract UnoptimizedVoting {
    
    // ❌ BAD: Using uint256 for everything (no storage packing)
    struct Proposal {
        address proposer;
        uint256 id;
        uint256 endTime;
        bool executed;
        uint256 yesVotes;
        uint256 noVotes;
        string description; // ❌ BAD: Storing large data in storage
    }
    
    // ❌ BAD: Not using immutable
    address public owner;
    uint256 public votingDuration;
    
    uint256 public proposalCount;
    
    mapping(uint256 => Proposal) public proposals;
    
    // ❌ BAD: Separate mappings instead of bit-packing
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => mapping(address => bool)) public voteChoice;
    
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    
    constructor(uint256 _votingDuration) {
        owner = msg.sender;
        votingDuration = _votingDuration;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    /**
     * ❌ BAD: Using memory instead of calldata
     * ❌ BAD: Storing description in storage
     * ❌ BAD: Not caching storage reads/writes
     */
    function createProposal(string memory description) 
        external 
        returns (uint256 proposalId) 
    {
        // ❌ BAD: Reading from storage multiple times
        proposalCount++;
        proposalId = proposalCount;
        
        uint256 endTime = block.timestamp + votingDuration;
        
        // ❌ BAD: Storing description in storage (very expensive!)
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            id: proposalId,
            endTime: endTime,
            executed: false,
            yesVotes: 0,
            noVotes: 0,
            description: description
        });
        
        emit ProposalCreated(proposalId, msg.sender);
    }
    
    /**
     * ❌ BAD: Multiple storage reads
     * ❌ BAD: Not caching values
     */
    function vote(uint256 proposalId, bool support) external {
        require(proposals[proposalId].endTime != 0, "Proposal does not exist");
        require(block.timestamp < proposals[proposalId].endTime, "Voting ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        
        uint256 weight = 1;
        
        // ❌ BAD: Separate storage writes
        hasVoted[proposalId][msg.sender] = true;
        voteChoice[proposalId][msg.sender] = support;
        
        // ❌ BAD: Reading and writing to storage separately
        if (support) {
            proposals[proposalId].yesVotes += weight;
        } else {
            proposals[proposalId].noVotes += weight;
        }
        
        emit Voted(proposalId, msg.sender, support);
    }
    
    /**
     * ❌ BAD: Using checked arithmetic in loop
     */
    function batchVote(
        uint256[] memory proposalIds,  // ❌ BAD: memory instead of calldata
        bool[] memory voteSupports     // ❌ BAD: memory instead of calldata
    ) external {
        require(proposalIds.length == voteSupports.length, "Length mismatch");
        
        // ❌ BAD: Reading length multiple times
        for (uint256 i = 0; i < proposalIds.length; i++) { // ❌ BAD: Checked arithmetic
            uint256 proposalId = proposalIds[i];
            bool support = voteSupports[i];
            
            require(proposals[proposalId].endTime != 0, "Proposal does not exist");
            require(block.timestamp < proposals[proposalId].endTime, "Voting ended");
            require(!hasVoted[proposalId][msg.sender], "Already voted");
            
            uint256 weight = 1;
            
            hasVoted[proposalId][msg.sender] = true;
            voteChoice[proposalId][msg.sender] = support;
            
            if (support) {
                proposals[proposalId].yesVotes += weight;
            } else {
                proposals[proposalId].noVotes += weight;
            }
            
            emit Voted(proposalId, msg.sender, support);
        }
    }
    
    function executeProposal(uint256 proposalId) external onlyOwner {
        require(proposals[proposalId].endTime != 0, "Proposal does not exist");
        require(block.timestamp >= proposals[proposalId].endTime, "Voting not ended");
        require(!proposals[proposalId].executed, "Already executed");
        
        proposals[proposalId].executed = true;
        
        bool passed = proposals[proposalId].yesVotes > proposals[proposalId].noVotes;
        
        emit ProposalExecuted(proposalId, passed);
    }
    
    function getProposal(uint256 proposalId)
        external
        view
        returns (
            address proposer,
            string memory description,
            uint256 endTime,
            uint256 yesVotes,
            uint256 noVotes,
            bool executed
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.description,
            proposal.endTime,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.executed
        );
    }
}

/**
 * GAS COMPARISON SUMMARY
 * ======================
 * 
 * Operation                | Unoptimized | Optimized (GasSaver) | Savings
 * -------------------------|-------------|----------------------|----------
 * Create Proposal (50ch)   | ~150,000    | ~90,000              | 40%
 * Vote                     | ~70,000     | ~50,000              | 29%
 * Batch Vote (5)           | ~300,000    | ~180,000             | 40%
 * Get Proposal             | Higher      | Lower                | ~30%
 * 
 * KEY DIFFERENCES:
 * 
 * 1. Storage Packing
 *    - Unoptimized: 7 storage slots per proposal
 *    - Optimized: 3 storage slots per proposal
 *    - Savings: ~80,000 gas per proposal
 * 
 * 2. Description Storage
 *    - Unoptimized: Stored in contract storage (~20,000 gas per 32 bytes)
 *    - Optimized: Stored in events (~8 gas per byte)
 *    - Savings: ~60,000 gas for 100-character description
 * 
 * 3. Voter State
 *    - Unoptimized: 2 storage slots (hasVoted + voteChoice)
 *    - Optimized: 1 storage slot (bit-packed)
 *    - Savings: ~20,000 gas per voter
 * 
 * 4. Calldata vs Memory
 *    - Unoptimized: Uses memory (requires copying)
 *    - Optimized: Uses calldata (direct reference)
 *    - Savings: ~2,000 gas per function call
 * 
 * 5. Immutable Variables
 *    - Unoptimized: Storage variables
 *    - Optimized: Immutable (in bytecode)
 *    - Savings: ~2,000 gas per read
 * 
 * 6. Loop Optimizations
 *    - Unoptimized: Checked arithmetic, multiple length reads
 *    - Optimized: Unchecked increment, cached length
 *    - Savings: ~100 gas per iteration
 * 
 * TOTAL ESTIMATED SAVINGS: 30-40% on average
 */
