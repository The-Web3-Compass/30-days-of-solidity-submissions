// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting {
    uint8 public proposalCount;

    struct Proposal {
        bytes32 name;          // 提案名称
        uint32 voteCount;      // 当前票数
        uint32 startTime;      // 投票开始时间（UNIX 时间戳）
        uint32 endTime;        // 投票结束时间
        bool executed;         // 是否已执行
    }

    // 提案 ID => 提案详情
    mapping(uint8 => Proposal) public proposals;

    // 地址 => bitmap（每一位表示是否对某个提案投票）
    mapping(address => uint256) private voterRegistry;

    // 提案 ID => 投票人数（不是票数，是真正的地址数）
    mapping(uint8 => uint32) public proposalVoterCount;

    // ---------------- Events ----------------
    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    // ---------------- Functions ----------------

    /// @notice 创建新提案
    function createProposal(bytes32 _name, uint32 _duration) external {
        require(_duration > 0, "Duration must be > 0");

        uint8 proposalId = proposalCount;
        proposalCount++;

        proposals[proposalId] = Proposal({
            name: _name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp + _duration),
            executed: false
        });

        emit ProposalCreated(proposalId, _name);
    }

    /// @notice 对某个提案进行投票
    function vote(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal ID");

        Proposal storage proposal = proposals[proposalId];
        uint32 currentTime = uint32(block.timestamp);

        require(currentTime >= proposal.startTime, "Voting not started");
        require(currentTime <= proposal.endTime, "Voting ended");

        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << proposalId;

        require((voterData & mask) == 0, "Already voted");

        // 标记已投票
        voterRegistry[msg.sender] = voterData | mask;

        proposal.voteCount++;
        proposalVoterCount[proposalId]++;

        emit Voted(msg.sender, proposalId);
    }

    /// @notice 执行投票（仅标记为已执行）
    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal ID");

        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp > proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Already executed");

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    /// @notice 查询某用户是否投过某个提案
    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        return (voterRegistry[voter] & (1 << proposalId)) != 0;
    }

    /// @notice 查询提案详情
    function getProposal(uint8 proposalId) external view returns (
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool executed,
        bool active
    ) {
        require(proposalId < proposalCount, "Invalid proposal ID");

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
