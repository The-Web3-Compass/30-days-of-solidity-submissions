/ SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GasEfficientVoting {
    // Limits us to 255 proposals, but fits in a uint8 (1 byte)
    uint8 public proposalCount;
    
    struct Proposal {
        bytes32 name;       // 32 bytes
        uint32 voteCount;   // 4 bytes
        uint32 startTime;   // 4 bytes
        uint32 endTime;     // 4 bytes
        bool executed;      // 1 byte
        // Total: 32 + 4 + 4 + 4 + 1 = 45 bytes.
        // Actually, name is one slot. The rest (4+4+4+1 = 13 bytes) pack into a SECOND slot.
        // Total storage slots used: 2. (Unoptimized would be 3 or 4).
    }

    mapping(uint8 => Proposal) public proposals;
    
    // Each user has a "bitmap". 
    // If bit 0 is '1', they voted on proposal 0.
    // If bit 5 is '1', they voted on proposal 5.
    mapping(address => uint256) private voterRegistry;

    function createProposal(bytes32 _name) external {
        proposalCount++;
        uint32 currentTime = uint32(block.timestamp);
        
        proposals[proposalCount] = Proposal({
            name: _name,
            voteCount: 0,
            startTime: currentTime,
            endTime: currentTime + 1 days,
            executed: false
        });
    }

    function vote(uint8 proposalId) external {
        require(proposalId <= proposalCount && proposalId > 0, "Invalid ID");
        
        // 1. Create a "mask". 
        // If proposalId is 2, mask is ...00100 (binary)
        uint256 mask = 1 << proposalId;
        
        // 2. Check if they already voted using bitwise AND (&)
        // If (registry & mask) is NOT zero, the bit was already set.
        require((voterRegistry[msg.sender] & mask) == 0, "Already voted");
        
        // 3. Mark as voted using bitwise OR (|)
        // This flips the specific bit to 1, leaving others unchanged.
        voterRegistry[msg.sender] |= mask;
        
        // 4. Increment count
        proposals[proposalId].voteCount++;
    }

    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        // Check the specific bit
        return (voterRegistry[voter] & (1 << proposalId)) != 0;
    }
}