// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasOptimizedVoting {
    // Packed data structure for proposal
    struct Proposal {
        uint128 voteCount;
        uint128 creationTime;
    }

    // Storage optimizations:
    // - proposals: array uses index as proposal ID
    // - voterBitmaps: packed boolean flags (1 bit per vote) 
    //   using nested mappings [voter][chunkIndex] -> uint256 bitmap
    Proposal[] public proposals;
    mapping(address => mapping(uint256 => uint256)) private voterBitmaps;

    event ProposalCreated(uint256 proposalId);
    event Voted(uint256 proposalId, address voter);

    // Create new proposal - optimized for minimal storage
    function createProposal() external {
         uint256 proposalId = proposals.length;
        proposals.push(Proposal({
            voteCount: 0,
            creationTime: uint128(block.timestamp)
        }));
        emit ProposalCreated(proposalId);
    }

    // Core vote function with gas optimizations
    function vote(uint256 proposalId) external {
        require(proposalId < proposals.length, "Invalid proposal");
        
        // Calculate bitmap position
        (uint256 chunk, uint256 bit) = _getBitmapPosition(proposalId);
        uint256 currentBitmap = voterBitmaps[msg.sender][chunk];
        
        // Check if already voted using bitwise operations
        require(currentBitmap & bit == 0, "Already voted");
        
        // Update storage - set bit flag and increment count
        voterBitmaps[msg.sender][chunk] = currentBitmap | bit;
        proposals[proposalId].voteCount++;
        
        emit Voted(proposalId, msg.sender);
    }

    // Helper to calculate bitmap position - pure for gas savings
    function _getBitmapPosition(uint256 proposalId) private pure returns (uint256 chunk, uint256 bit) {
        chunk = proposalId / 256;
        bit = 1 << (proposalId % 256);
    }

    // View function to check vote status - uses calldata for inputs
    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        (uint256 chunk, uint256 bit) = _getBitmapPosition(proposalId);
        return (voterBitmaps[voter][chunk] & bit) != 0;
    }
}