// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting {

    uint8 public proposalCount;
    struct Proposal {
        bytes32 name; // 固定长度的 32 字节数组
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }

    // 定义3个映射: 提案id -> 提案, 用户地址 -> 用户投票情况, 提案id -> 提案得票数
    mapping(uint8 => Proposal) public proposals;
    mapping(address => uint256) private voterRegistry;
    mapping(uint8 => uint32) public proposalVoterCount;

    // 定义3个事件: 提案创建, 投票, 提案执行
    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    // 提案创建, 编号从0开始
    function createProposal(bytes32 _name, uint32 duration) external {
        require(duration > 0, "Duration must be greater than 0");
        uint8 proposalId = proposalCount;
        proposalCount++;
        Proposal storage proposal = proposals[proposalId];
        proposal.name = _name;
        proposal.voteCount = 0;
        proposal.startTime = uint32(block.timestamp);
        proposal.endTime = uint32(block.timestamp) + duration;
        proposal.executed = false;
        emit ProposalCreated(proposalId, _name);
    }

    // 投票
    function vote(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.startTime && block.timestamp < proposal.endTime, "Voting is not active");

        uint256 voterData = voterRegistry[msg.sender];
        require((voterData >> proposalId) & 1 == 0, "Already voted"); // 根据voterData的二进制表示从右往左的第n位是否位1判断提案n是否已被投票
        voterRegistry[msg.sender] = voterData | (1 << proposalId); // 将voterData的二进制表示的第n位置为1

        proposal.voteCount++;
        proposalVoterCount[proposalId]++;

        emit Voted(msg.sender, proposalId);
    }

    // 执行提案
    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Proposal already executed");
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    // 是否已投票
    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        return (voterRegistry[voter] >> proposalId) & 1 == 1;
    }

    // 获取提案信息
    function getProposal(uint8 proposalId) external view returns (bytes32 name, uint32 voteCount, 
        uint32 startTime, uint32 endTime, bool executed, bool active) {
        require(proposalId < proposalCount, "Invalid proposal");

        Proposal storage proposal = proposals[proposalId];
        return (proposal.name, proposal.voteCount, proposal.startTime, proposal.endTime, proposal.executed, 
            block.timestamp >= proposal.startTime && block.timestamp < proposal.endTime);
    }
}