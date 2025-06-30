// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract DecentralizedGovernance is ReentrancyGuard{
    using SafeCast for uint256;

    struct Proposal{
        uint256 id;
        string description;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        address proposer;
        bytes[] executionData;
        address[] executionTargets;
        uint256 executionTime;
    }

    mapping (uint256 => Proposal) public proposals;
    mapping (uint256 => mapping(address => bool)) public hasVoted;
    mapping (uint256 => mapping(address => uint256)) public votingPowerSnapshots;

    IERC20 public governanceToken;
    uint256 public nextProposalId;
    uint256 public votingDuration;
    uint256 public timelockDuration;
    address public admin;
    uint256 public quorumPercentage = 5;
    uint256 public proposalDepositAmount = 10;

    event ProposalCreated(uint256 id, string description, address proposer, uint256 depositAmount);
    event Voted(uint256 proposalId, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 id, bool passed);
    event QuorumNotMet(uint256 id, uint256 votesTotal, uint256 quorumNeeded);
    event ProposalDepositPaid(address proposer, uint256 amount);
    event ProposalDepositRefunded(address proposer, uint256 amount);
    event TimelockSet(uint256 duration);
    event ProposalTimelockStarted(uint256 proposalId, uint256 executionTime);

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can call this");
        _;
    }

    modifier validProposal(uint256 proposalId) {
        require(proposalId < nextProposalId, "Proposal does not exist");
        _;
    }

    constructor(address _governanceToken, uint256 _votingDuration, uint256 _timelockDuration) {
        require(_governanceToken != address(0), "Invalid token address");
        require(_votingDuration > 0, "Invalid voting duration");
        require(_timelockDuration > 0, "Invalid timelock duration");
        
        governanceToken = IERC20(_governanceToken);
        votingDuration = _votingDuration;
        timelockDuration = _timelockDuration;
        admin = msg.sender;
        emit TimelockSet(_timelockDuration);
    }

function setQuorumPercentage(uint256 _quorumPercentage) external onlyAdmin {
    require(_quorumPercentage > 0 && _quorumPercentage <= 100,"Invalid quorum percentage");
    quorumPercentage = _quorumPercentage;
}

function setProposalDepositAmount(uint256 _proposalDepositAmount) external onlyAdmin{
    require(_proposalDepositAmount > 0, "Invalid deposit amount");
    proposalDepositAmount = _proposalDepositAmount;
}

function setTimelockDuration(uint256 _timelockDuration) external onlyAdmin {
    require(_timelockDuration > 0, "Invalid timelock duration");
    timelockDuration = _timelockDuration;
    emit TimelockSet(_timelockDuration);
}

function createProposal(
    string calldata _description,
    address[] calldata _targets,
    bytes[] calldata _calldatas
) external returns(uint256) {
    require(bytes(_description).length > 0, "Empty description");
    require(governanceToken.balanceOf(msg.sender) >= proposalDepositAmount,"Insufficient tokens for deposit");
    require(_targets.length == _calldatas.length,"Invalid data lengths");
    require(_targets.length > 0, "No execution targets");

    for (uint256 i = 0; i < _targets.length; i++) {
        require(_targets[i] != address(0), "Invalid target address");
    }

    require(governanceToken.transferFrom(msg.sender, address(this), proposalDepositAmount), "Transfer failed");

    emit ProposalDepositPaid(msg.sender, proposalDepositAmount);

    uint256 currentProposalId = nextProposalId;
    
    proposals[currentProposalId] = Proposal({
        id : currentProposalId,
        description : _description,
        deadline : block.timestamp + votingDuration,
        votesFor : 0,
        votesAgainst : 0,
        executed : false,
        proposer : msg.sender,
        executionData : _calldatas,
        executionTargets : _targets,
        executionTime : 0
    });
    
    emit ProposalCreated(currentProposalId, _description, msg.sender, proposalDepositAmount);

    nextProposalId++;
    return currentProposalId;
}

function vote(uint256 proposalId, bool support) external validProposal(proposalId) {
    Proposal storage proposal = proposals[proposalId];
    require(block.timestamp < proposal.deadline,"Voting period over");
    require(!hasVoted[proposalId][msg.sender],"Already voted");
    
    uint256 weight = governanceToken.balanceOf(msg.sender);
    require(weight > 0,"No voting power");
    
    votingPowerSnapshots[proposalId][msg.sender] = weight;
    
    if(support){
        proposal.votesFor += weight;
    } else {
        proposal.votesAgainst += weight;
    }
    hasVoted[proposalId][msg.sender] = true;

    emit Voted(proposalId, msg.sender, support, weight);
}

function finalizeProposal(uint256 proposalId) external validProposal(proposalId) {
    Proposal storage proposal = proposals[proposalId];
    require(block.timestamp >= proposal.deadline,"voting period not yet over");
    require(!proposal.executed,"already finalized");
    require(proposal.executionTime == 0,"Execution already in progress");

    uint256 totalSupply = governanceToken.totalSupply();
    require(totalSupply > 0, "No tokens in circulation");
    
    uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
    uint256 quorumNeeded = (totalSupply * quorumPercentage) / 100;

    if(totalVotes >= quorumNeeded && proposal.votesFor > proposal.votesAgainst){
        proposal.executionTime = block.timestamp + timelockDuration;
        emit ProposalTimelockStarted(proposalId, proposal.executionTime);
    } else {
        proposal.executed = true;
        
        if(totalVotes < quorumNeeded) {
            require(governanceToken.transfer(proposal.proposer, proposalDepositAmount), "Refund failed");
            emit ProposalDepositRefunded(proposal.proposer, proposalDepositAmount);
            emit QuorumNotMet(proposalId, totalVotes, quorumNeeded);
        }
        
        emit ProposalExecuted(proposalId, false);
    }
}

function executeProposal(uint256 proposalId) external nonReentrant validProposal(proposalId){
    Proposal storage proposal = proposals[proposalId];
    require(!proposal.executed,"Proposal already executed");
    require(proposal.executionTime > 0 && block.timestamp >= proposal.executionTime,"Execution not ready");

    proposal.executed = true;
    bool passed = proposal.votesFor > proposal.votesAgainst;

    if(passed){
        for (uint256 i = 0; i < proposal.executionTargets.length; i++){
            (bool success, bytes memory returnData) = proposal.executionTargets[i].call(proposal.executionData[i]);
            require(success, string(abi.encodePacked("Call failed at index ", _toString(i), ": ", returnData)));
        }
        
        require(governanceToken.transfer(proposal.proposer, proposalDepositAmount), "Refund failed");
        emit ProposalDepositRefunded(proposal.proposer, proposalDepositAmount);
    }
    
    emit ProposalExecuted(proposalId, passed);
}

function getProposalResult(uint256 proposalId) external view validProposal(proposalId) returns(string memory){
    Proposal storage proposal = proposals[proposalId];
    require(proposal.executed || proposal.executionTime > 0,"Proposal not finalized");

    uint256 totalSupply = governanceToken.totalSupply();
    uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
    uint256 quorumNeeded = (totalSupply * quorumPercentage) / 100;

    if(totalVotes < quorumNeeded) {
        return "Proposal Failed - Quorum Not Met";
    } else if (proposal.votesFor > proposal.votesAgainst){
        return "Proposal Passed";
    } else {
        return "Proposal Rejected";
    }
}

function getProposalDetails(uint256 proposalId) external view validProposal(proposalId) returns(Proposal memory){
    return proposals[proposalId];
}

function _toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
        return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
    }
    return string(buffer);
}

function emergencyTokenRecovery(address token, address to, uint256 amount) external onlyAdmin {
    require(token != address(governanceToken), "Cannot withdraw governance tokens");
    require(to != address(0), "Invalid recipient");
    IERC20(token).transfer(to, amount);
}
}