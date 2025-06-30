/**
 * @title DecentralizedGovernance
 * @dev 去中心化治理系统 - DAO治理框架
 * 
 * 基础概念：
 * DAO(去中心化自治组织)是一种基于智能合约的组织形式，所有决策通过代币持有者投票决定。
 * 类似于数字世界的民主议会，任何重大决策都需要通过提案和投票来执行。
 * 
 * 核心机制：
 * 1. 治理代币：
 *    - 代表投票权重的数字资产
 *    - 持有越多代币，投票权重越大
 *    - 用于提案和投票的基础
 * 
 * 2. 提案系统：
 *    - 需要100代币才能发起提案
 *    - 提案包含具体执行内容和说明
 *    - 可以调用任意合约执行决议
 * 
 * 3. 投票机制：
 *    - 投票选项：赞成、反对、弃权
 *    - 投票权重 = 提案创建时的代币余额
 *    - 需要1000代币参与才能达到法定人数
 * 
 * 4. 时间管理：
 *    - 提案延迟期：1天（冷静期）
 *    - 投票期限：7天
 *    - 自动状态转换
 * 
 * 5. 执行流程：
 *    - 提案创建 -> 等待期 -> 投票期
 *    - 投票通过 -> 执行提案内容
 *    - 投票失败或取消 -> 提案关闭
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract DecentralizedGovernance is ReentrancyGuard {
    using Counters for Counters.Counter;

    // 状态变量
    IERC20 public governanceToken;  // 治理代币
    Counters.Counter public proposalCount;  // 提案计数器

    // 投票权重快照
    mapping(address => mapping(uint256 => uint256)) public votingPowerSnapshot;  // 用户在提案创建时的投票权重

    // 提案状态枚举
    enum ProposalState {
        Pending,    // 等待中
        Active,     // 激活的
        Canceled,   // 已取消
        Defeated,   // 已失败
        Succeeded,  // 已成功
        Executed    // 已执行
    }

    // 投票类型枚举
    enum VoteType {
        Against,    // 反对
        For,        // 赞成
        Abstain    // 弃权
    }

    // 提案结构体
    struct Proposal {
        uint256 id;                 // 提案ID
        address proposer;           // 提案人
        string description;         // 提案描述
        uint256 startTime;         // 开始时间
        uint256 endTime;           // 结束时间
        address[] targets;         // 目标合约地址
        uint256[] values;          // 调用金额
        bytes[] calldatas;         // 调用数据
        bool executed;             // 是否已执行
        bool canceled;             // 是否已取消
        uint256 forVotes;          // 赞成票数
        uint256 againstVotes;      // 反对票数
        uint256 abstainVotes;      // 弃权票数
        mapping(address => bool) hasVoted;  // 投票记录
    }

    // 添加提案视图结构体
    struct ProposalView {
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        ProposalState state;
    }

    // 配置参数
    uint256 public constant VOTING_DELAY = 1 days;      // 提案延迟时间
    uint256 public constant VOTING_PERIOD = 7 days;     // 投票期限
    uint256 public constant PROPOSAL_THRESHOLD = 100e18; // 提案门槛（100代币）
    uint256 public constant QUORUM_VOTES = 1000e18;     // 法定投票数（1000代币）

    // 提案映射
    mapping(uint256 => Proposal) public proposals;

    // 事件
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        string description,
        uint256 startTime,
        uint256 endTime
    );

    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        uint8 support,
        uint256 weight
    );

    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    constructor(address _governanceToken) {
        governanceToken = IERC20(_governanceToken);
    }

    /**
     * @dev 创建提案
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256) {
        require(
            governanceToken.balanceOf(msg.sender) >= PROPOSAL_THRESHOLD,
            "Insufficient voting power"
        );
        require(
            targets.length == values.length && targets.length == calldatas.length,
            "Invalid proposal"
        );

        proposalCount.increment();
        uint256 proposalId = proposalCount.current();

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.startTime = block.timestamp + VOTING_DELAY;
        newProposal.endTime = newProposal.startTime + VOTING_PERIOD;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.calldatas = calldatas;

        // 记录投票权重快照
        votingPowerSnapshot[msg.sender][proposalId] = governanceToken.balanceOf(msg.sender);

        emit ProposalCreated(
            proposalId,
            msg.sender,
            targets,
            values,
            calldatas,
            description,
            newProposal.startTime,
            newProposal.endTime
        );

        return proposalId;
    }

    /**
     * @dev 投票
     */
    function castVote(
        uint256 proposalId,
        uint8 support
    ) external nonReentrant {
        require(
            state(proposalId) == ProposalState.Active,
            "Proposal not active"
        );
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.hasVoted[msg.sender], "Already voted");

        uint256 votes = votingPowerSnapshot[msg.sender][proposalId];
        require(votes > 0, "No voting power");

        if (support == uint8(VoteType.Against)) {
            proposal.againstVotes += votes;
        } else if (support == uint8(VoteType.For)) {
            proposal.forVotes += votes;
        } else {
            proposal.abstainVotes += votes;
        }

        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(msg.sender, proposalId, support, votes);
    }

    /**
     * @dev 执行提案
     */
    function execute(uint256 proposalId) external payable nonReentrant {
        require(
            state(proposalId) == ProposalState.Succeeded,
            "Proposal not succeeded"
        );
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            (bool success, ) = proposal.targets[i].call{value: proposal.values[i]}(
                proposal.calldatas[i]
            );
            require(success, "Transaction execution reverted");
        }

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev 取消提案
     */
    function cancel(uint256 proposalId) external {
        require(
            state(proposalId) == ProposalState.Pending ||
            state(proposalId) == ProposalState.Active,
            "Cannot cancel completed proposal"
        );
        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.proposer, "Only proposer can cancel");

        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    /**
     * @dev 获取提案状态
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (block.timestamp <= proposal.startTime) {
            return ProposalState.Pending;
        }

        if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;
        }

        if (proposal.forVotes <= proposal.againstVotes || 
            proposal.forVotes + proposal.againstVotes + proposal.abstainVotes < QUORUM_VOTES) {
            return ProposalState.Defeated;
        }

        return ProposalState.Succeeded;
    }

    /**
     * @dev 获取提案详细信息
     */
    function getProposal(uint256 proposalId) external view returns (ProposalView memory) {
        Proposal storage proposal = proposals[proposalId];
        
        return ProposalView({
            proposer: proposal.proposer,
            description: proposal.description,
            startTime: proposal.startTime,
            endTime: proposal.endTime,
            executed: proposal.executed,
            canceled: proposal.canceled,
            forVotes: proposal.forVotes,
            againstVotes: proposal.againstVotes,
            abstainVotes: proposal.abstainVotes,
            state: state(proposalId)
        });
    }

    /**
     * @dev 获取用户在某个提案的投票权重
     */
    function getVotingPower(address account, uint256 proposalId) external view returns (uint256) {
        return votingPowerSnapshot[account][proposalId];
    }

    /**
     * @dev 检查用户是否已对某个提案投票
     */
    function hasVoted(uint256 proposalId, address account) external view returns (bool) {
        return proposals[proposalId].hasVoted[account];
    }

    /**
     * @dev 接收ETH
     */
    receive() external payable {}
}