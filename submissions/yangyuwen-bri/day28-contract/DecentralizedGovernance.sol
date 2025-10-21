// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 引入OpenZeppelin的ERC20接口，方便与治理代币交互
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// 引入安全类型转换库，防止溢出
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
// 引入防重入攻击的安全模块
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Decentralized Governance System (ERC-20 Based)
/// @notice 一个带有加权投票、法定人数、提案押金和延时执行的DAO治理合约
contract DecentralizedGovernance is ReentrancyGuard {
    using SafeCast for uint256; // 给uint256类型增加安全转换功能

    // 提案结构体，记录提案的所有关键信息
    struct Proposal {
        uint256 id; // 提案ID
        string description; // 提案描述
        uint256 deadline; // 投票截止时间戳
        uint256 votesFor; // 支持票数（加权）
        uint256 votesAgainst; // 反对票数（加权）
        bool executed; // 是否已执行
        address proposer; // 提案人地址
        bytes[] executionData; // 执行目标合约的calldata
        address[] executionTargets; // 目标合约地址
        uint256 executionTime; // timelock到期后可执行的时间戳
    }

    IERC20 public governanceToken; // 治理代币（ERC20）
    mapping(uint256 => Proposal) public proposals; // 提案ID到提案详情的映射
    mapping(uint256 => mapping(address => bool)) public hasVoted; // 记录每个提案每个地址是否已投票

    uint256 public nextProposalId; // 下一个提案ID
    uint256 public votingDuration; // 投票持续时间（秒）
    uint256 public timelockDuration; // timelock延时时长（秒）
    address public admin; // 管理员（合约部署者）
    uint256 public quorumPercentage = 5; // 法定人数百分比（默认5%）
    uint256 public proposalDepositAmount = 10; // 提案押金数量（默认10个代币）

    // 事件声明，方便前端和用户追踪合约状态变化
    event ProposalCreated(uint256 id, string description, address proposer, uint256 depositAmount);
    event Voted(uint256 proposalId, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 id, bool passed);
    event QuorumNotMet(uint256 id, uint256 votesTotal, uint256 quorumNeeded);
    event ProposalDepositPaid(address proposer, uint256 amount);
    event ProposalDepositRefunded(address proposer, uint256 amount);
    event TimelockSet(uint256 duration);
    event ProposalTimelockStarted(uint256 proposalId, uint256 executionTime);

    // 只允许管理员调用的修饰符
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this");
        _;
    }

    /// @notice 构造函数，初始化合约参数
    /// @param _governanceToken 治理代币合约地址
    /// @param _votingDuration 投票持续时间（秒）
    /// @param _timelockDuration timelock延时时长（秒）
    constructor(address _governanceToken, uint256 _votingDuration, uint256 _timelockDuration) {
        governanceToken = IERC20(_governanceToken);
        votingDuration = _votingDuration;
        timelockDuration = _timelockDuration;
        admin = msg.sender;
        emit TimelockSet(_timelockDuration);
    }

    /// @notice 设置法定人数百分比（管理员权限）
    function setQuorumPercentage(uint256 _quorumPercentage) external onlyAdmin {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100");
        quorumPercentage = _quorumPercentage;
    }

    /// @notice 设置提案押金数量（管理员权限）
    function setProposalDepositAmount(uint256 _proposalDepositAmount) external onlyAdmin {
        proposalDepositAmount = _proposalDepositAmount;
    }

    /// @notice 设置timelock延时时长（管理员权限）
    function setTimelockDuration(uint256 _timelockDuration) external onlyAdmin {
        timelockDuration = _timelockDuration;
        emit TimelockSet(_timelockDuration);
    }

    /// @notice 创建新提案
    /// @param _description 提案描述
    /// @param _targets 目标合约地址数组
    /// @param _calldatas 目标合约的calldata数组
    /// @return 新提案的ID
    function createProposal(
        string calldata _description,
        address[] calldata _targets,
        bytes[] calldata _calldatas
    ) external returns (uint256) {
        // 检查提案人是否有足够的代币作为押金
        require(governanceToken.balanceOf(msg.sender) >= proposalDepositAmount, "Insufficient tokens for deposit");
        // 检查目标合约和calldata数量是否一致
        require(_targets.length == _calldatas.length, "Targets and calldatas length mismatch");
        // 转账押金到合约
        governanceToken.transferFrom(msg.sender, address(this), proposalDepositAmount);
        emit ProposalDepositPaid(msg.sender, proposalDepositAmount);

        // 创建并存储提案
        proposals[nextProposalId] = Proposal({
            id: nextProposalId,
            description: _description,
            deadline: block.timestamp + votingDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposer: msg.sender,
            executionData: _calldatas,
            executionTargets: _targets,
            executionTime: 0
        });
        emit ProposalCreated(nextProposalId, _description, msg.sender, proposalDepositAmount);
        nextProposalId++;
        return nextProposalId - 1;
    }

    /// @notice 对某个提案进行投票
    /// @param proposalId 提案ID
    /// @param support 是否支持（true为支持，false为反对）
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        // 检查是否在投票期内
        require(block.timestamp < proposal.deadline, "Voting period over");
        // 检查投票人是否有治理代币
        require(governanceToken.balanceOf(msg.sender) > 0, "No governance tokens");
        // 检查是否已投票
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        // 投票权重=当前持有的治理代币数量
        uint256 weight = governanceToken.balanceOf(msg.sender);
        if (support) {
            proposal.votesFor += weight;
        } else {
            proposal.votesAgainst += weight;
        }
        hasVoted[proposalId][msg.sender] = true;
        emit Voted(proposalId, msg.sender, support, weight);
    }

    /// @notice 结算提案，判断是否通过并进入timelock
    /// @param proposalId 提案ID
    function finalizeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        // 必须在投票期结束后
        require(block.timestamp >= proposal.deadline, "Voting period not yet over");
        // 不能重复结算
        require(!proposal.executed, "Proposal already executed");
        // 不能重复设置timelock
        require(proposal.executionTime == 0, "Execution time already set");

        uint256 totalSupply = governanceToken.totalSupply();
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumNeeded = (totalSupply * quorumPercentage) / 100;

        // 达到法定人数且支持票多于反对票，进入timelock
        if (totalVotes >= quorumNeeded && proposal.votesFor > proposal.votesAgainst) {
            proposal.executionTime = block.timestamp + timelockDuration;
            emit ProposalTimelockStarted(proposalId, proposal.executionTime);
        } else {
            // 否则直接标记为已执行
            proposal.executed = true;
            emit ProposalExecuted(proposalId, false);
            if (totalVotes < quorumNeeded) {
                emit QuorumNotMet(proposalId, totalVotes, quorumNeeded);
            }
        }
    }

    /// @notice 执行提案（timelock到期后）
    /// @param proposalId 提案ID
    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        // 不能重复执行
        require(!proposal.executed, "Proposal already executed");
        // 必须timelock到期
        require(proposal.executionTime > 0 && block.timestamp >= proposal.executionTime, "Timelock not yet expired");
        // 先标记为已执行，防止重入攻击
        proposal.executed = true;
        bool passed = proposal.votesFor > proposal.votesAgainst;
        if (passed) {
            // 循环执行所有目标合约的操作
            for (uint256 i = 0; i < proposal.executionTargets.length; i++) {
                (bool success, bytes memory returnData) = proposal.executionTargets[i].call(proposal.executionData[i]);
                require(success, string(returnData));
            }
            emit ProposalExecuted(proposalId, true);
            // 提案通过，退还押金
            governanceToken.transfer(proposal.proposer, proposalDepositAmount);
            emit ProposalDepositRefunded(proposal.proposer, proposalDepositAmount);
        } else {
            // 提案未通过，不退押金
            emit ProposalExecuted(proposalId, false);
        }
    }

    /// @notice 查询提案结果
    /// @param proposalId 提案ID
    /// @return 提案结果字符串
    function getProposalResult(uint256 proposalId) external view returns (string memory) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.executed, "Proposal not yet executed");
        uint256 totalSupply = governanceToken.totalSupply();
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumNeeded = (totalSupply * quorumPercentage) / 100;
        if (totalVotes < quorumNeeded) {
            return "Proposal FAILED - Quorum not met";
        } else if (proposal.votesFor > proposal.votesAgainst) {
            return "Proposal PASSED";
        } else {
            return "Proposal REJECTED";
        }
    }

    /// @notice 查询提案详情
    /// @param proposalId 提案ID
    /// @return Proposal结构体
    function getProposalDetails(uint256 proposalId) external view returns (Proposal memory) {
        return proposals[proposalId];
    }
}
