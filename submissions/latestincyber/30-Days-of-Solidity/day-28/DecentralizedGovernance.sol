// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DecentralizedGovernance is ReentrancyGuard {
    IERC20 public governanceToken;
    uint256 public proposalCount;
    uint256 public constant VOTING_PERIOD = 3 days; // voting period for each proposal
    uint256 public constant TIMELOCK_PERIOD = 2 days; // time lock period after proposal execution before it can be executed
    uint256 public constant QUORUM_PERCENTAGE = 20; // 10% of total supply must vote for proposal to be valid
    uint256 public constant PROPOSAL_DEPOSIT = 100 * 10 ** 18; // 100 governance tokens required to create a proposal

    struct Proposal {
        uint256 id; // unique identifier
        address proposer; // who created it
        string description; // what it does
        uint256 deadline; // when voting ends
        uint256 votesFor; // total votes in favour
        uint256 votesAgainst; // total votes against 
        bool executed; // has it been executed
        bool cancelled; // has it been cancelled
        uint256 executionTime; // when it can be executed (after timelock)
        bytes[] executionData; // function calls to make (if proposal passes)
        address[] executionTargets; // contracts to call (if proposal passes)
        mapping(address => bool) hasVoted; // track who voted
    }

    mapping(uint256 => Proposal) public proposals; // proposal ID to Proposal

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
        // 1. require deposit to prevent spam
        require(
            governanceToken.transferFrom(msg.sender, address(this), PROPOSAL_DEPOSIT),
            "Deposit transfer failed"
        );

        // 2. create the proposal
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + VOTING_PERIOD;
        newProposal.executionData = _data;
        newProposal.executionTargets = _targets;

        emit ProposalCreated(proposalCount, msg.sender, _description);
        return proposalCount;
    }

    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];

        // 1. validation checks
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(!proposal.executed, "Already executed");

        // 2. get voters' token balance (voting power)
        uint256 voterWeight = governanceToken.balanceOf(msg.sender);
        require(voterWeight > 0, "No voting power");

        // 3. record the vote
        proposal.hasVoted[msg.sender] = true; // mark as voted

        if (_support) {
            proposal.votesFor += voterWeight;
        } else {
            proposal.votesAgainst += voterWeight;
        }
        proposal.hasVoted[msg.sender] = true; // 3. record the vote

        emit Voted(_proposalId, msg.sender, _support, voterWeight);
    }

    function finalize(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp >= proposal.deadline, "Voting still active");
        require(!proposal.executed, "Already executed");

        // calculate quorum 
        uint256 totalSupply = governanceToken.totalSupply();
        uint256 quorumRequired = (totalSupply * QUORUM_PERCENTAGE) / 100;
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;

        require(totalVotes >= quorumRequired, "Quorum not met");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal rejected");

        // set execution time (after timelock)
        proposal.executionTime = block.timestamp + TIMELOCK_PERIOD;
    }

    function execute(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        require(proposal.executionTime > 0, "Not finalized");
        require(block.timestamp >= proposal.executionTime, "Timelock active");
        require(!proposal.executed, "Already executed");

        proposal.executed = true; // mark as executed before making calls to prevent reentrancy

        // execute all the calls
        for (uint256 i = 0; i < proposal.executionTargets.length; i++) {
            (bool success, ) = proposal.executionTargets[i].call(proposal.executionData[i]);
            require(success, "Execution failed");
        }

        // return deposit to proposer
        governanceToken.transfer(proposal.proposer, PROPOSAL_DEPOSIT);

        emit ProposalExecuted(_proposalId);
    }
}