// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GasSaver {
    uint8 public proposalCount;
    
    struct Proposal {
        bytes32 name;
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }

    mapping(uint8 => Proposal) public proposals;
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
        uint256 mask = 1 << proposalId;
        require(proposalId <= proposalCount && proposalId > 0, "Invalid ID");
        require((voterRegistry[msg.sender] & mask) == 0, "Already voted");
        
        voterRegistry[msg.sender] |= mask;
        proposals[proposalId].voteCount++;
    }

    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        return (voterRegistry[voter] & (1 << proposalId)) != 0;
    }
}
