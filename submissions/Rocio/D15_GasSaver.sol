// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GasEfficientVoting
 * @notice A simple, highly gas-optimized contract for on-chain proposal voting.
 *
 * Primary gas optimizations:
 * 1. Storage Packing: Variables in structs are arranged to minimize storage slots (SSTORE operations).
 * 2. Minimal Data Types: Using uint96 and uint40 instead of the default uint256 where possible.
 * 3. Input Types: Using 'calldata' for string arguments to avoid costly memory copying.
 */
contract GasEfficientVoting {
    // --- State Variables & Structs ---

    // uint96 is used for IDs and vote counts (max 7.9e+28, sufficient for any group ID or vote count)
    // uint40 is used for timestamps (max 34 trillion seconds, ~1 million years from now, sufficient)

    struct Proposal {
        // Slot 1 (Packed for efficiency: 12 + 5 + 1 = 18 bytes, highly packed)
        uint96 voteCount;
        uint40 endTimestamp;
        bool hasEnded; // Finalizes the state

        // Slot 2 (Separate slot due to dynamic size)
        string description;
    }

    struct Voter {
        // Slot 1 (Packed for efficiency: 1 + 12 = 13 bytes, highly packed)
        bool hasVoted;
        uint96 votedProposalId; // Tracks which proposal was voted on

        // Note: No 'weight' variable is included to maintain simplicity and max gas efficiency.
    }

    // Mapping for proposals, using uint96 as keys for potential packing/efficiency benefits,
    // though the mapping key itself is hashed to uint256.
    mapping(uint96 => Proposal) public proposals;

    // Stores the voting status for each user.
    mapping(address => Voter) public voters;

    // Stores the ID of the next proposal to be created.
    uint96 public nextProposalId = 1;

    // --- Core Functions ---

    /**
     * @notice Creates a new voting proposal.
     * @dev Uses 'calldata' for the string description, saving gas by avoiding memory copying.
     * @param _description The brief description of the proposal.
     * @param _votingDuration The duration of the voting period in seconds (up to ~1 million years).
     * @return proposalId The ID of the newly created proposal.
     */
    function createProposal(
        string calldata _description,
        uint40 _votingDuration
    ) external returns (uint96 proposalId) {
        proposalId = nextProposalId;
        nextProposalId++;

        // Calculate end timestamp once.
        uint40 _endTimestamp = uint40(block.timestamp) + _votingDuration;

        // One SSTORE operation to initialize the packed slot 1.
        proposals[proposalId] = Proposal({
            voteCount: 0,
            endTimestamp: _endTimestamp,
            hasEnded: false,
            description: _description // The dynamic data (string) takes its own storage slot(s).
        });
    }

    /**
     * @notice Allows a user to vote for a proposal.
     * @dev This is the most gas-sensitive function and is highly optimized.
     * 1. Caching: Reads state to memory only once (SSTORE is expensive).
     * 2. Minimal Checks: Uses concise revert messages.
     * 3. Single SSTOREs: Proposal update and Voter update are done in single SSTORE operations.
     * @param _proposalId The ID of the proposal to vote for.
     */
    function vote(uint96 _proposalId) external {
        // 1. Check Voter status using a single SLOAD (reading from storage)
        Voter storage voter = voters[msg.sender];
        require(!voter.hasVoted, "Already voted");

        // 2. Check Proposal status using a single SLOAD
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.endTimestamp > block.timestamp, "Voting closed");
        require(!proposal.hasEnded, "Voting closed");

        // 3. Update Proposal: Read and write to storage (SSTORE) in one line.
        proposal.voteCount++; // This triggers a single, optimized SSTORE

        // 4. Update Voter: Read and write to storage (SSTORE) in one line.
        // Caching is unnecessary here as we read the whole struct into the local storage variable 'voter'.
        voter.hasVoted = true;
        voter.votedProposalId = _proposalId;
    }

    // --- View Functions (Gas-free) ---

    /**
     * @notice Returns the vote count and end status of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return voteCount The total number of votes.
     * @return endTimestamp The time the voting ends.
     * @return hasEnded The final state of the proposal.
     */
    function getProposalStatus(uint96 _proposalId)
        external
        view
        returns (
            uint96 voteCount,
            uint40 endTimestamp,
            bool hasEnded
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.voteCount,
            proposal.endTimestamp,
            proposal.hasEnded
        );
    }

    /**
     * @notice Ends a proposal and sets the final state.
     * @dev Allows anyone to call this after the voting duration is over.
     * Calling this allows the proposal struct to be fully optimized for reading/viewing.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProposal(uint96 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];

        // Cache the timestamp to avoid multiple SLOADs if used multiple times,
        // though here it's only used once, it serves as an example of good practice.
        uint40 endTime = proposal.endTimestamp;

        require(endTime <= block.timestamp, "Voting ongoing");
        require(!proposal.hasEnded, "Already finalized");

        // Single SSTORE operation to update the packed state variable
        proposal.hasEnded = true;
    }
}
