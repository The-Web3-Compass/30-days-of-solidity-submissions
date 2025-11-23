     
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Decentralized Governance System (ERC-20 Based)
/// @notice A DAO with weighted voting, quorum, proposal deposit, and timelock.
contract DecentralizedGovernance is ReentrancyGuard {
    using SafeCast for uint256;

    // 提案结构体
    struct Proposal {
        uint256 id;
        string description;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        address proposer;
        bytes[] executionData;      // 提案相关的数据
        address[] executionTargets; // 提案相关的数据要发送的地址
        uint256 executionTime;      // 时间锁解除后提案可正式执行的未来时间戳
    }

    // 有投票权的治理代币
    IERC20 public governanceToken;
    // 提案ID -> 提案详细信息
    mapping(uint256 => Proposal) public proposals;
    // 提案ID -> (选民 -> 是否投票)
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public nextProposalId;        // 下一个提案ID(提案ID从0开始)
    uint256 public votingDuration;        // 提案可投票时长(单位为秒)
    uint256 public timelockDuration;      // 时间锁的时长, 即提案通过后在正式执行前的等待期
    address public admin;                 // 合约属主(管理员)
    uint256 public quorumPercentage = 5;  // 提案通过必须达到的最小投票率百分比
    uint256 public proposalDepositAmount = 10;  // 创建提案所需的押金

    event ProposalCreated(uint256 id, string description, address proposer, uint256 depositAmount); // 提案创建事件
    event Voted(uint256 proposalId, address voter, bool support, uint256 weight);  // 投票事件
    event ProposalExecuted(uint256 id, bool passed);                               // 提案执行完成事件(会告知提案本身是通过还是失败)
    event QuorumNotMet(uint256 id, uint256 votesTotal, uint256 quorumNeeded);      // 投票率未达标事件
    event ProposalDepositPaid(address proposer, uint256 amount);                   // 提案押金支付完成事件
    event ProposalDepositRefunded(address proposer, uint256 amount);               // 提案押金归还完成事件
    event TimelockSet(uint256 duration);                                           // 时间锁设置事件
    event ProposalTimelockStarted(uint256 proposalId, uint256 executionTime);      // 提案时间锁启动事件

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this");
        _;
    }

    constructor(address _governanceToken, uint256 _votingDuration, uint256 _timelockDuration) {
        governanceToken = IERC20(_governanceToken);
        votingDuration = _votingDuration;
        timelockDuration = _timelockDuration;
        admin = msg.sender;
        emit TimelockSet(_timelockDuration);
    }

    // 设置最少投票比率
    function setQuorumPercentage(uint256 _quorumPercentage) external onlyAdmin {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100");
        quorumPercentage = _quorumPercentage;
    }

    // 设置提案押金金额
    function setProposalDepositAmount(uint256 _proposalDepositAmount) external onlyAdmin {
        proposalDepositAmount = _proposalDepositAmount;
    }

    // 设置时间锁持续时长
    function setTimelockDuration(uint256 _timelockDuration) external onlyAdmin {
        timelockDuration = _timelockDuration;
        emit TimelockSet(_timelockDuration);
    }

    // 创建提案
    function createProposal(
        string calldata _description,
        address[] calldata _targets,
        bytes[] calldata _calldatas
    ) external returns (uint256) {
        require(governanceToken.balanceOf(msg.sender) >= proposalDepositAmount, "Insufficient tokens for deposit");
        require(_targets.length == _calldatas.length, "Targets and calldatas length mismatch");

        governanceToken.transferFrom(msg.sender, address(this), proposalDepositAmount);
        emit ProposalDepositPaid(msg.sender, proposalDepositAmount);

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

    // 投票
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.deadline, "Voting period over");
        require(governanceToken.balanceOf(msg.sender) > 0, "No governance tokens");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        // 投票权重为代币余额
        uint256 weight = governanceToken.balanceOf(msg.sender);

        if (support) {
            proposal.votesFor += weight;
        } else {
            proposal.votesAgainst += weight;
        }

        hasVoted[proposalId][msg.sender] = true;

        emit Voted(proposalId, msg.sender, support, weight);
    }

    // 确认提案投票结果
    function finalizeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.deadline, "Voting period not yet over");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.executionTime == 0, "Execution time already set");

        uint256 totalSupply = governanceToken.totalSupply();
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumNeeded = (totalSupply * quorumPercentage) / 100;

        if (totalVotes >= quorumNeeded && proposal.votesFor > proposal.votesAgainst) {
            // 提案通过设置时间锁
            proposal.executionTime = block.timestamp + timelockDuration;
            emit ProposalTimelockStarted(proposalId, proposal.executionTime);
        } else {
            proposal.executed = true;
            emit ProposalExecuted(proposalId, false);
            if (totalVotes < quorumNeeded) {
                emit QuorumNotMet(proposalId, totalVotes, quorumNeeded);
            }
        }
    }

    // 执行提案
    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(proposal.executionTime > 0 && block.timestamp >= proposal.executionTime, "Timelock not yet expired");

        proposal.executed = true; // set early to prevent reentrancy

        bool passed = proposal.votesFor > proposal.votesAgainst;

        if (passed) {
            for (uint256 i = 0; i < proposal.executionTargets.length; i++) {
                (bool success, bytes memory returnData) = proposal.executionTargets[i].call(proposal.executionData[i]);
                require(success, string(returnData));
            }
            emit ProposalExecuted(proposalId, true);
            // 退还提案押金
            governanceToken.transfer(proposal.proposer, proposalDepositAmount);
            emit ProposalDepositRefunded(proposal.proposer, proposalDepositAmount);
        } else {
            emit ProposalExecuted(proposalId, false);
        }
    }

    // 查询提案执行结果
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

    // 查询提案详细信息
    function getProposalDetails(uint256 proposalId) external view returns (Proposal memory) {
        return proposals[proposalId];
    }
}

