// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting {
    
    uint8 public proposalCount; // 提案数量
    
    struct Proposal {
        bytes32 name;       // 使用 bytes32 节省 gas
        uint32 voteCount;   // 投票数
        uint32 startTime;   // 开始时间
        uint32 endTime;     // 结束时间
        bool executed;      // 是否已执行
    }
    
    mapping(uint8 => Proposal) public proposals;
    mapping(address => uint256) private voterRegistry; // 记录投票状态（二进制位标记）
    mapping(uint8 => uint32) public proposalVoterCount; // 每个提案的投票人数
    
    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);
    
    // 创建新提案
    function createProposal(bytes32 name, uint32 duration) external {
        require(duration > 0, "Duration must be > 0");
        
        uint8 proposalId = proposalCount;
        proposalCount++;
        
        proposals[proposalId] = Proposal({
            name: name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + duration,
            executed: false
        });
        
        emit ProposalCreated(proposalId, name);
    }
    
    // 对提案投票
    function vote(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        
        uint32 currentTime = uint32(block.timestamp);
        require(currentTime >= proposals[proposalId].startTime, "Voting not started");
        require(currentTime <= proposals[proposalId].endTime, "Voting ended");
        
        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << proposalId;
        require((voterData & mask) == 0, "Already voted");
        
        voterRegistry[msg.sender] = voterData | mask;
        
        proposals[proposalId].voteCount++;
        proposalVoterCount[proposalId]++;
        
        emit Voted(msg.sender, proposalId);
    }
    
    // 执行提案
    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        require(block.timestamp > proposals[proposalId].endTime, "Voting not ended");
        require(!proposals[proposalId].executed, "Already executed");
        
        proposals[proposalId].executed = true;
        emit ProposalExecuted(proposalId);
        
        // 可在此添加执行逻辑
    }
    
    // 查询某地址是否已对某提案投票
    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        return (voterRegistry[voter] & (1 << proposalId)) != 0;
    }
    
    // 获取提案详情
    function getProposal(uint8 proposalId) external view returns (
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool executed,
        bool active
    ) {
        require(proposalId < proposalCount, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.name,
            proposal.voteCount,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            (block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime)
        );
    }
}