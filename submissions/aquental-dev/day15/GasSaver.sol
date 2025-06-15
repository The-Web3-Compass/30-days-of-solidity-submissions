// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Gas-optimized voting system for proposals
contract GasSaver {
    // Events for logging votes and proposals (cheaper than storage)
    event ProposalCreated(
        uint32 indexed proposalId,
        string description,
        uint64 deadline
    );
    event Voted(uint32 indexed proposalId, address indexed voter, bool vote);

    // Packed storage: fits in one 32-byte slot (256 bits)
    struct Proposal {
        uint128 yesVotes; // 128 bits
        uint128 noVotes; // 128 bits (total 256 bits)
        uint64 deadline; // 64 bits
        bool active; // 8 bits (total 72 bits in second slot)
    }

    // Proposal ID to Proposal data (minimize storage usage)
    mapping(uint32 => Proposal) private proposals;
    // Tracks if an address voted on a proposal (packed to one slot per voter)
    mapping(uint32 => mapping(address => bool)) private hasVoted;
    // Counter for proposal IDs (uint32 to save gas over uint256)
    uint32 private proposalCount;

    // Constructor: No initialization needed to save deployment gas

    // Creates a new proposal with a description and voting duration
    // Uses calldata for description to avoid memory copying
    // Gas optimizations: Minimal storage writes, emits event for logging
    function createProposal(
        string calldata description,
        uint64 duration
    ) external returns (uint32) {
        uint32 currentId = proposalCount++;
        Proposal storage proposal = proposals[currentId];

        // Write to storage once (deadline and active)
        proposal.deadline = uint64(block.timestamp) + duration;
        proposal.active = true;

        // Emit event instead of storing description in storage
        emit ProposalCreated(currentId, description, proposal.deadline);
        return currentId;
    }

    // Allows voting on a proposal (true = yes, false = no)
    // Uses calldata for minimal gas, caches storage reads
    // Gas optimizations: Single storage read/write, event for logging
    function vote(uint32 proposalId, bool voteChoice) external {
        Proposal storage proposal = proposals[proposalId];

        // Cache storage reads to memory (saves SLOADs)
        bool isActive = proposal.active;
        uint64 deadline = proposal.deadline;

        // Validate proposal (gas-efficient checks)
        require(isActive, "Proposal inactive");
        require(block.timestamp <= deadline, "Voting closed");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        // Mark voter to prevent double voting (one storage write)
        hasVoted[proposalId][msg.sender] = true;

        // Update vote count (single storage write, reuse memory)
        if (voteChoice) {
            proposal.yesVotes += 1;
        } else {
            proposal.noVotes += 1;
        }

        // Emit event instead of storing vote details
        emit Voted(proposalId, msg.sender, voteChoice);
    }

    // Returns proposal details (read-only, no gas cost for caller)
    // Gas optimizations: Direct storage read, no memory copying
    function getProposal(
        uint32 proposalId
    )
        external
        view
        returns (
            uint128 yesVotes,
            uint128 noVotes,
            uint64 deadline,
            bool active
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.yesVotes,
            proposal.noVotes,
            proposal.deadline,
            proposal.active
        );
    }

    // Closes a proposal to prevent further voting
    // Gas optimizations: Single storage write, reusable for cleanup
    function closeProposal(uint32 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.active, "Already closed");
        require(block.timestamp > proposal.deadline, "Voting still open");

        // Single storage write to deactivate
        proposal.active = false;
    }
}
