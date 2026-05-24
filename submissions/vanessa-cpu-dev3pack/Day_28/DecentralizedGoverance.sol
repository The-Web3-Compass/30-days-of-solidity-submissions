// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DecentralizedGovernance is ReentrancyGuard {
    IERC20 public governanceToken;
    uint256 public proposalCount;
    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant TIMELOCK_PERIOD = 2 days;
    uint256 public constant QUORUM_PERCENTAGE = 10; // 10% of total supply
    uint256 public constant PROPOSAL_DEPOSIT = 100 * 10**18; // 100 tokens
    
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool cancelled;
        uint256 executionTime;
        bytes[] executionData;
        address[] executionTargets;
        mapping(address => bool) hasVoted;
    }
    
    mapping(uint256 => Proposal) public proposals;
    
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    
    constructor(address _governanceToken) {
        governanceToken = IERC20(_governanceToken);
    }
    
    function createProposal(
        string memory _description,
        address[] memory _targets,
        bytes[] memory _data
    ) external returns (uint256) {
        // 1. Require deposit to prevent spam
        require(
            governanceToken.transferFrom(msg.sender, address(this), PROPOSAL_DEPOSIT),
            "Deposit failed"
        );
        
        // 2. Create the proposal
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + VOTING_PERIOD;
        newProposal.executionTargets = _targets;
        newProposal.executionData = _data;
        
        emit ProposalCreated(proposalCount, msg.sender, _description);
        return proposalCount;
    }

    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        
        // 1. Validation checks
        require(block.timestamp < proposal.deadline, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(!proposal.executed, "Already executed");
        
        // 2. Get voter's token balance (voting power)
        uint256 weight = governanceToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");
        
        // 3. Record the vote
        proposal.hasVoted[msg.sender] = true;
        
        if (_support) {
            proposal.votesFor += weight;
        } else {
            proposal.votesAgainst += weight;
        }
        
        emit Voted(_proposalId, msg.sender, _support, weight);
    }

    function finalize(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp >= proposal.deadline, "Voting still active");
        require(!proposal.executed, "Already executed");
        
        // Calculate quorum
        uint256 totalSupply = governanceToken.totalSupply();
        uint256 quorumRequired = (totalSupply * QUORUM_PERCENTAGE) / 100;
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        
        require(totalVotes >= quorumRequired, "Quorum not met");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal rejected");
        
        // Set execution time (timelock)
        proposal.executionTime = block.timestamp + TIMELOCK_PERIOD;
    }

    function execute(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.executionTime > 0, "Not finalized");
        require(block.timestamp >= proposal.executionTime, "Timelock active");
        require(!proposal.executed, "Already executed");
        
        proposal.executed = true;
        
        // Execute all the calls
        for (uint256 i = 0; i < proposal.executionTargets.length; i++) {
            (bool success, ) = proposal.executionTargets[i].call(proposal.executionData[i]);
            require(success, "Execution failed");
        }
        
        // Return deposit to proposer
        governanceToken.transfer(proposal.proposer, PROPOSAL_DEPOSIT);
        
        emit ProposalExecuted(_proposalId);
    }
}