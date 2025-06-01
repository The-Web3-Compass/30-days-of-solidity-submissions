// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedGovernance is ReentrancyGuard {
    using SafeCast for uint256;

    struct Proposal{
        uint id;
        string description;
        uint votesFor;
        uint votesAgainst;
        uint executionTime;
        address proposer;
        uint deadline;
        bool executed;
        bytes[] executionData;
        address[] executionTargets;
    }

    mapping (uint => Proposal) public proposals;
    mapping(uint => mapping(address => bool)) public hasVoted; //* proposalId->voter address-> has voted

    IERC20 public governanceToken;
    uint public votingDuration;
    uint public timeLockDuration;
    uint public nextProposalId;
    address public admin;
    uint public quorumPercentage = 5;
    uint public proposalDepositAmount = 10;

    event ProposalCreated(uint id, address indexed proposer, string desc,uint depositAmount );
    event Voted(uint proposalId, address voter, bool support, uint weight);
    event ProposalExecuted(uint id, bool status);
    event ProposalDepositPaid(address proposer, uint amount);
    event ProposalDepositRefunded(address proposer, uint amount);
    event QuorumNotMet(uint id, uint votesTotal, uint quorumNeeded);
    event TimeLockSet(uint duration);
    event propsalTimeLockStarted(uint id, uint executionTime);

    modifier onlyAdmin(){
        require(msg.sender == admin, "only admin cal call this");
        _;
    }

    constructor(address _governanceToken, uint _votingDuration,uint _timeLockDuration ){
        governanceToken = IERC20(_governanceToken);
       admin = msg.sender;
       votingDuration = _votingDuration;
       timeLockDuration = _timeLockDuration;

        emit TimeLockSet(_timeLockDuration);
    }

    function setQuorumPercentage(uint _quorumPercentage) external onlyAdmin() {
        require(_quorumPercentage <= 10, "must be btw 0 to 10");
        quorumPercentage = _quorumPercentage;
    }

    function setTimeLock(uint _timeLockDuration) external onlyAdmin(){
        timeLockDuration = _timeLockDuration;
        emit TimeLockSet(_timeLockDuration);
    }

    function crateProposal(
        string calldata _description,
        address[] calldata _targets,
        bytes[] calldata _calldatas
    ) external returns(uint256){
        require(governanceToken.balanceOf(msg.sender) >= proposalDepositAmount, "not enough governancve token to create a proposal");
        require(_targets.length == _calldatas.length, "targets and calldata length is a mismatch");

        governanceToken.transferFrom(msg.sender, address(this), proposalDepositAmount);

        emit ProposalDepositPaid(msg.sender, proposalDepositAmount);

        proposals[nextProposalId] = Proposal({
            id: nextProposalId,
            description: _description,
            votesFor: 0,
            votesAgainst: 0,
            executionTime: 0,
            proposer: msg.sender,
            deadline: block.timestamp + votingDuration,
            executed: false,
            executionData: _calldatas,
            executionTargets: _targets
        });

        emit ProposalCreated(nextProposalId, msg.sender, _description, proposalDepositAmount);
        nextProposalId++;

        return nextProposalId -1;
    }

    function vote(uint _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.deadline, "voting period is over");
        require(!hasVoted[_proposalId][msg.sender], "already voted");
        require(governanceToken.balanceOf(msg.sender) > 0, "no governance tokens on this proposal");
 
        uint weight = governanceToken.balanceOf(msg.sender);
        if(_support){
            proposal.votesFor += weight;
        }else{
            proposal.votesAgainst += weight;
        }
 
        hasVoted[_proposalId][msg.sender] = true;
 
        emit Voted(_proposalId, msg.sender, _support, weight);
    }

    function finalizeProposal(uint _proposalId) external onlyAdmin() {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.deadline, "voting period is not over");
        require(!proposal.executed, "already executed");
        require(proposal.executionTime == 0, "execution time is already set");

        uint totalSupply = governanceToken.totalSupply();
        uint totalVotes = proposal.votesAgainst + proposal.votesFor;
        uint quorumNeeded = (quorumPercentage * totalSupply)/100;

        if(totalVotes >= quorumNeeded && proposal.votesFor > proposal.votesAgainst){
            proposal.executionTime = block.timestamp + timeLockDuration;
            emit propsalTimeLockStarted(proposal.id, proposal.executionTime);
        }else{
            proposal.executed = true;
            emit ProposalExecuted(proposal.id, false);

            if(totalVotes < quorumNeeded){
                emit QuorumNotMet(proposal.id, totalVotes, quorumNeeded);
            }
        }
    }

    function executeProposal(uint _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "already executed");
        require(proposal.executionTime > 0 && block.timestamp >= proposal.executionTime, "timelock has not seexpired yet");
        proposal.executed = true;
        bool passed = proposal.votesFor > proposal.votesAgainst;
        if(passed){
            for(uint i=0; i < proposal.executionTargets.length ; i++){
                (bool success, bytes memory returnData ) = proposal.executionTargets[i].call(proposal.executionData[i]);
                require(success, string(returnData));
            }

            emit ProposalExecuted(proposal.id, true);
            governanceToken.transfer(proposal.proposer, proposalDepositAmount);
            emit ProposalDepositRefunded(proposal.proposer, proposalDepositAmount);
        }else{
            emit ProposalExecuted(proposal.id, false);
        }
    }

    function getProposalResult(uint _proposalId) external view returns(string memory) {
        Proposal memory proposal = proposals[_proposalId];
        require(proposal.executed, "not yet executed");
        
        uint totalSupply = governanceToken.totalSupply();
        uint totalVotes = proposal.votesAgainst + proposal.votesFor;
        uint quorumNeeded = (quorumPercentage * totalSupply)/100;

        if(totalVotes < quorumNeeded){
            return "PROPOSAL FAILED - quorum not met";
        }else if(proposal.votesFor > proposal.votesAgainst){
            return "PROPOSAL PASSED";
        }else{
            return "PROPOSAL FAILED";
        }
    }

    function getProposalDetails(uint _proposalId) external view returns(Proposal memory){
        return proposals[_proposalId];
    }
}