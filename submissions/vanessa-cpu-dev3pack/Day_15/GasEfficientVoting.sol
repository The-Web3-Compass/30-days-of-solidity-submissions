//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting {
    // Limit us to 255 proposals, but fits in a uint8 (1 byte)
    uint8 public proposalCount;

    struct Proposal {
        bytes32 name;   //32 bytes - Slot 0
        uint32 voteCount;      // 4 bytes
        uint32 startTime;  // 4 bytes  | Slot 1 (13 bytes total)
        uint32 endTime;   // 4 bytes   |
        bool executed;    // 1 byte    
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
        
        // 1. Create a "mask" for this proposal
        uint256 mask = 1 << proposalId;
        
        // 2. Check if they already voted using bitwise AND
        require((voterRegistry[msg.sender] & mask) == 0, "Already voted");
        
        // 3. Mark as voted using bitwise OR
        voterRegistry[msg.sender] |= mask;
        
        // 4. Increment count
        // Optimization: load struct into memory if updating multiple fields, 
        // but here we just update one.
        proposals[proposalId].voteCount++;
    }

    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        return (voterRegistry[voter] & (1 << proposalId)) != 0;
    }
}