// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting {
    uint8 public proposalCount;
    
    struct Proposal {
        bytes32 name;       // 32 bytes
        uint32 voteCount;   // 4 bytes  |
        uint32 startTime;   // 4 bytes  | 打包在同一槽位
        uint32 endTime;     // 4 bytes  |
        bool executed;      // 1 byte   |
    }
    
    mapping(uint8 => Proposal) public proposals;
    
    mapping(address => uint256) private voterRegistry;
    mapping(uint8 => uint32) public proposalVoterCount;
    
    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    function createProposal(bytes32 name, uint32 duration) external {
        uint8 proposalId = proposalCount;
        proposalCount++;
        
        Proposal memory newProposal = Proposal({
            name: name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp + duration),
            executed: false
        });
        
        proposals[proposalId] = newProposal;
        emit ProposalCreated(proposalId, name);
    }
    
    function vote(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        require(block.timestamp >= proposals[proposalId].startTime, "Not started");
        require(block.timestamp <= proposals[proposalId].endTime, "Ended");
        require(!proposals[proposalId].executed, "Already executed");
        
        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << proposalId;
        
        require((voterData & mask) == 0, "Already voted");
        
        voterRegistry[msg.sender] = voterData | mask;
        proposals[proposalId].voteCount++;
        proposalVoterCount[proposalId]++;
        
        emit Voted(msg.sender, proposalId);
    }
    
    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        require(block.timestamp > proposals[proposalId].endTime, "Not ended");
        require(!proposals[proposalId].executed, "Already executed");
        
        proposals[proposalId].executed = true;
        emit ProposalExecuted(proposalId);
    }
    
    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        return (voterRegistry[voter] & (1 << proposalId)) != 0;
    }
    
    function getProposal(uint8 proposalId) external view returns (
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool executed
    ) {
        Proposal memory p = proposals[proposalId];
        return (p.name, p.voteCount, p.startTime, p.endTime, p.executed);
    }
}