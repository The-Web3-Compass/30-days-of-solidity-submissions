// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title 治理代币 (GovernanceToken)
 * @dev 一个具有投票快照功能的ERC20代币。
 */
contract GovernanceToken is ERC20Votes, ERC20Permit, Ownable {
    constructor(
        address initialOwner
    ) ERC20("Governance Token", "GOV") ERC20Permit("Governance Token") Ownable(initialOwner) {
        _mint(initialOwner, 1000000 * (10**decimals()));
    }

    /**
     * @dev 允许所有者铸造新代币（用于治理需要）
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // 以下函数是Solidity为实现ERC20Votes功能所要求的必需重写。
    function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._update(from, to, amount);
    }

    function nonces(address owner) public view virtual override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}

/**
 * @title 去中心化治理 (DecentralizedGovernance)
 * @dev 一个用于代币化治理的简单DAO合约。
 */
contract DecentralizedGovernance is Ownable, ReentrancyGuard {
    
    enum ProposalState {
        Active,
        Defeated,
        Succeeded,
        Executed,
        Canceled
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        ProposalState state;
    }

    GovernanceToken public immutable governanceToken;
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // 治理参数
    uint256 public constant QUORUM_PERCENT = 4; // 4% 法定人数
    uint256 public constant VOTING_PERIOD_BLOCKS = 5760; // 投票期：约1天的区块数
    uint256 public constant PROPOSAL_THRESHOLD = 1000 * 10**18; // 最小提案阈值：1000代币

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool inFavor, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    error InvalidProposalId();
    error InsufficientVotingPower();
    error VotingNotStarted();
    error VotingEnded();
    error AlreadyVoted();
    error ProposalNotActive();
    error QuorumNotReached();
    error ProposalDefeated();
    error ProposalAlreadyExecuted();
    error OnlyProposerCanCancel();

    constructor(address _tokenAddress) Ownable(msg.sender) {
        governanceToken = GovernanceToken(_tokenAddress);
    }

    /**
     * @dev 创建新提案
     */
    function propose(string calldata _description) external returns (uint256) {
        if (governanceToken.getVotes(msg.sender) < PROPOSAL_THRESHOLD) {
            revert InsufficientVotingPower();
        }

        uint256 proposalId = ++proposalCount;
        
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            startBlock: block.number,
            endBlock: block.number + VOTING_PERIOD_BLOCKS,
            forVotes: 0,
            againstVotes: 0,
            state: ProposalState.Active
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
        return proposalId;
    }

    /**
     * @dev 对提案进行投票
     */
    function vote(uint256 _proposalId, bool _inFavor) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        
        if (proposal.id == 0) revert InvalidProposalId();
        if (proposal.state != ProposalState.Active) revert ProposalNotActive();
        if (block.number < proposal.startBlock) revert VotingNotStarted();
        if (block.number > proposal.endBlock) revert VotingEnded();
        if (hasVoted[_proposalId][msg.sender]) revert AlreadyVoted();

        uint256 votingPower = governanceToken.getPastVotes(msg.sender, proposal.startBlock);
        if (votingPower == 0) revert InsufficientVotingPower();

        hasVoted[_proposalId][msg.sender] = true;

        if (_inFavor) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }

        emit Voted(_proposalId, msg.sender, _inFavor, votingPower);
    }

    /**
     * @dev 执行通过的提案
     */
    function execute(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        
        if (proposal.id == 0) revert InvalidProposalId();
        if (proposal.state != ProposalState.Active) revert ProposalNotActive();
        if (block.number <= proposal.endBlock) revert VotingNotStarted();

        uint256 totalSupply = governanceToken.getPastTotalSupply(proposal.startBlock);
        uint256 quorum = (totalSupply * QUORUM_PERCENT) / 100;
        
        if (proposal.forVotes < quorum) {
            proposal.state = ProposalState.Defeated;
            revert QuorumNotReached();
        }
        
        if (proposal.forVotes <= proposal.againstVotes) {
            proposal.state = ProposalState.Defeated;
            revert ProposalDefeated();
        }

        proposal.state = ProposalState.Executed;

        // 在真实的DAO中，这里会执行提案定义的操作
        // 例如，调用另一个合约、转移资金等。
        // 在此示例中，我们仅将其标记为已执行。

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev 取消提案（仅提案发起者可以取消）
     */
    function cancel(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        
        if (proposal.id == 0) revert InvalidProposalId();
        if (proposal.state != ProposalState.Active) revert ProposalNotActive();
        if (msg.sender != proposal.proposer) revert OnlyProposerCanCancel();

        proposal.state = ProposalState.Canceled;
        emit ProposalCanceled(_proposalId);
    }

    /**
     * @dev 获取提案状态
     */
    function getProposalState(uint256 _proposalId) external view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        
        if (proposal.state != ProposalState.Active) {
            return proposal.state;
        }
        
        if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        }
        
        uint256 totalSupply = governanceToken.getPastTotalSupply(proposal.startBlock);
        uint256 quorum = (totalSupply * QUORUM_PERCENT) / 100;
        
        if (proposal.forVotes < quorum || proposal.forVotes <= proposal.againstVotes) {
            return ProposalState.Defeated;
        }
        
        return ProposalState.Succeeded;
    }

    /**
     * @dev 获取提案详情
     */
    function getProposal(uint256 _proposalId) external view returns (
        uint256 id,
        address proposer,
        string memory description,
        uint256 startBlock,
        uint256 endBlock,
        uint256 forVotes,
        uint256 againstVotes,
        ProposalState state
    ) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.startBlock,
            proposal.endBlock,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.state
        );
    }

    /**
     * @dev 检查用户是否已对某提案投票
     */
    function hasVotedOnProposal(uint256 _proposalId, address _voter) external view returns (bool) {
        return hasVoted[_proposalId][_voter];
    }

    /**
     * @dev 获取法定人数要求
     */
    function getQuorum(uint256 _proposalId) external view returns (uint256) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        
        uint256 totalSupply = governanceToken.getPastTotalSupply(proposal.startBlock);
        return (totalSupply * QUORUM_PERCENT) / 100;
    }
}