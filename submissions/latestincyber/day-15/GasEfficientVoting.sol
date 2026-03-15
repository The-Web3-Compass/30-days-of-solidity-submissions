// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting {
    // Limits to 255 proposals, fits in a uint8 (1 byte)
    uint8 public proposalCount;

    struct Proposal {
        bytes32 name; // 32 bytes
        uint32 voteCount; // 4 bytes
        uint32 startTime; // 4 bytes
        uint32 endTime; // 4 bytes
        bool executed; // 1 byte
        // Total is 32 + 4 + 4 + 4 + 1 = 45 bytes, using two storage slots (32 + 13 bytes)
    }

    mapping(uint8 => Proposal) public proposals; // Maps proposal ID to Proposal
    mapping(address => uint256) private voterRegistery; // Maps voter address to a bitmap of votes (up to 256 proposals)

    function createProposal(bytes32 _name) external {
        proposalCount++;
        uint32 currentTime = uint32(block.timestamp);

        proposals[proposalCount] = Proposal({
            name: _name,
            voteCount: 0,
            startTime: currentTime,
            endTime: currentTime + 7 days, // Voting period of 7 days
            executed: false
        });
    }

    function vote(uint8 proposalId) external {
        require(proposalId <= proposalCount && proposalId > 0, "Invalid ID");

        uint256 mask = 1 << proposalId; // Create a mask for the proposal ID
        require(voterRegistery[msg.sender] & mask == 0, "Already voted"); // Check if user has already voted
        voterRegistery[msg.sender] |= mask; // Mark the user as having voted 
        proposals[proposalId].voteCount++; // Increment vote count
    }

    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        return (voterRegistery[voter] & (1 << proposalId)) != 0; // Check if the bit for the proposal ID is set
    }
}