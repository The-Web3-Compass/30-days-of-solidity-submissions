// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedGovernance is ReentrancyGuard {
    IERC20 public governanceToken;

    struct Proposal {
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
        uint256 timelockEnd;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public nextProposalId;
    uint256 public votingDuration;
    uint256 public timelockDuration;
    address public admin;
    uint256 public quorumPercentage;
    uint256 public proposalDepositAmount;

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event QuorumNotMet(uint256 indexed proposalId);
    event ProposalTimelockStarted(uint256 indexed proposalId);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(
        address _governanceToken,
        uint256 _votingDuration,
        uint256 _timelockDuration,
        uint256 _quorumPercentage,
        uint256 _proposalDepositAmount
    ) {
        require(_governanceToken != address(0), "Invalid token");
        require(_votingDuration > 0, "Invalid duration");
        require(_quorumPercentage > 0 && _quorumPercentage <= 100, "Invalid quorum");

        governanceToken = IERC20(_governanceToken);
        votingDuration = _votingDuration;
        timelockDuration = _timelockDuration;
        admin = msg.sender;
        quorumPercentage = _quorumPercentage;
        proposalDepositAmount = _proposalDepositAmount;
    }

    // 创建提案
    function createProposal(string memory description) external returns (uint256) {
        require(bytes(description).length > 0, "Empty description");

        // 收取提案押金
        if (proposalDepositAmount > 0) {
            governanceToken.transferFrom(msg.sender, address(this), proposalDepositAmount);
        }

        uint256 proposalId = nextProposalId++;

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            description: description,
            forVotes: 0,
            againstVotes: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            executed: false,
            canceled: false,
            timelockEnd: 0
        });

        emit ProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }

    // 投票
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp >= proposal.startTime, "Not started");
        require(block.timestamp <= proposal.endTime, "Ended");
        require(!proposal.executed, "Already executed");
        require(!proposal.canceled, "Canceled");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        uint256 weight = governanceToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.forVotes += weight;
        } else {
            proposal.againstVotes += weight;
        }

        emit Voted(proposalId, msg.sender, support, weight);
    }

    // 完成提案（进入时间锁或取消）
    function finalizeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp > proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Already executed");
        require(!proposal.canceled, "Canceled");

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 totalSupply = governanceToken.totalSupply();
        uint256 quorumRequired = (totalSupply * quorumPercentage) / 100;

        if (totalVotes >= quorumRequired && proposal.forVotes > proposal.againstVotes) {
            if (timelockDuration > 0) {
                proposal.timelockEnd = block.timestamp + timelockDuration;
                emit ProposalTimelockStarted(proposalId);
            } else {
                proposal.executed = true;
                _refundDeposit(proposalId);
                emit ProposalExecuted(proposalId);
            }
        } else {
            proposal.canceled = true;
            emit QuorumNotMet(proposalId);
        }
    }

    // 执行提案
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.timelockEnd > 0, "No timelock set");
        require(block.timestamp >= proposal.timelockEnd, "Timelock not ended");
        require(!proposal.executed, "Already executed");
        require(!proposal.canceled, "Canceled");

        proposal.executed = true;
        _refundDeposit(proposalId);

        emit ProposalExecuted(proposalId);
    }

    // 退还押金
    function _refundDeposit(uint256 proposalId) internal {
        if (proposalDepositAmount > 0) {
            Proposal storage proposal = proposals[proposalId];
            governanceToken.transfer(proposal.proposer, proposalDepositAmount);
        }
    }

    // 获取提案结果
    function getProposalResult(uint256 proposalId) external view returns (
        bool passed,
        uint256 forVotes,
        uint256 againstVotes,
        bool executed
    ) {
        Proposal memory proposal = proposals[proposalId];
        passed = proposal.forVotes > proposal.againstVotes;
        return (passed, proposal.forVotes, proposal.againstVotes, proposal.executed);
    }

    // 管理员设置参数
    function setQuorumPercentage(uint256 _newQuorum) external onlyAdmin {
        require(_newQuorum > 0 && _newQuorum <= 100, "Invalid quorum");
        quorumPercentage = _newQuorum;
    }

    function setProposalDepositAmount(uint256 _newAmount) external onlyAdmin {
        proposalDepositAmount = _newAmount;
    }
}
