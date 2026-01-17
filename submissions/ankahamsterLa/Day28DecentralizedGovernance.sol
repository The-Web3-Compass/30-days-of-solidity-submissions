//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// Build a DAO which is short name for decentralized autonomous organization.
// 1. Propose an idea (after locking a token deposit)
// 2. Let the community vote based on how many tokens they hold
// 3. Ensure a minimum number of voters participate(quorum)
// 4. Add a waiting period after the vote(timelock)
// 5. Automatically execute the winning proposal's actions if the vote passes

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// In solidity, when handle with data of different types like downcast numbers without checking, the data would overflow or trunate values without realizing it.
// When dealing with some number involving token decimals, it can make sure that casting number safely.
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedGovernance is ReentrancyGuard{
    using SafeCast for uint256;
    

    struct Proposal{
        uint256 id;
        string description;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        address proposer;// The address of the person who created the proposal
        bytes[] executionData;// The actual data payloads to be called on other contracts if the proposal passes.
        address[] executionTargets;// The list of contract addresses that these payloads should be sent to.
        uint256 executionTime;// A future timestamp after the timelock when the proposal can officially be executed.
    }

    // More tokens, more weight in the proposal decision.
    IERC20 public governanceToken; // The governanceToken is the ERC-20 token that represents voting power.
    mapping(uint256=>Proposal) public proposals;// proposal id=>information of proposal
    mapping(uint256=>mapping(address=>bool)) public hasVoted;// proposal id=>voter's address=>voted or not

    uint256 public nextProposalId;// This track the next ID that will be assigned when someone creates a new proposal.
    uint256 public votingDuration;
    uint256 public timelockDuration;// This is the waiting period after a proposal wins before it can actually be executed.
    address public admin;
    uint256 public quorumPercentage=5;// This sets the minumum percentage of total values that must participate for proposal to be valid.
    uint256 public proposalDepositAmount=10;// This defines how many governance tokens a user must lock when creating a proposal.

    event ProposalCreated(uint256 id,string description,address proposer,uint256 depositAmount);
    event Voted(uint256 proposalId,address voter,bool support,uint256 weight);
    event ProposalExecuted(uint256 id,bool passed);
    // It records if a proposal fails because not enough people participated.
    event QuorumNotMet(uint256 id,uint256 votesTotal,uint256 quorumNeeded);
    event ProposalDepositPaid(address proposer,uint256 amount);
    // If a proposal passes and is executed, the proposer can get their deposit back.
    event ProposalDepositRefunded(address proposer,uint256 amount);
    event TimelockSet(uint256 duration);
    // When a proposal wins the vote but enters the timelock delay before execution.
    event ProposalTimelockStarted(uint256 proposalId,uint256 executionTime);
   

    modifier onlyAdmin(){
        require(msg.sender==admin,"Only Admin can call this");
        _;

    }

    constructor(address _governanceToken,uint256 _votingDuration,uint256 _timelockDuration){
        // require(_governanceToken!=address(0),"Invalid token");
        // require(_votingDuration>0,"Invalid duration");
        // require(_quorumPercentage>0&& _quorumPercentage<=100,"Invalid quorum");

        governanceToken=IERC20(_governanceToken);
        votingDuration=_votingDuration;
        timelockDuration=_timelockDuration;
        admin=msg.sender;
        emit TimelockSet(_timelockDuration);
    }

    function setQuorumPercentage(uint256 _quorumPercentage) external onlyAdmin{
        require(_quorumPercentage<=100,"Quorum percentage must be between 0 and 100");
        quorumPercentage=_quorumPercentage;
    }

    function setProposalDepositAmount(uint256 _proposalDepositAmount) external onlyAdmin{
        proposalDepositAmount=_proposalDepositAmount;
    }
    
    function setTimelockDuration(uint256 _timelockDuration) external onlyAdmin{
        timelockDuration=_timelockDuration;
        emit TimelockSet(_timelockDuration);
    }

    // "_targets": the addressed of the contracts this proposal will interact with
    // "_calldatas": the actual function call data that will be sent to each target
    function createProposal(string calldata _description,address[] calldata _targets,bytes[] calldata _calldatas) external returns(uint256){
        require(governanceToken.balanceOf(msg.sender)>=proposalDepositAmount,"Insufficient tokens for deposit");
        // Each target contract must have one corresponding function call.
        require(_targets.length ==_calldatas.length,"Targets and calldatas length mismatch");
        governanceToken.transferFrom(msg.sender,address(this),proposalDepositAmount);

        emit ProposalDepositPaid(msg.sender,proposalDepositAmount);

        proposals[nextProposalId]=Proposal({
            id:nextProposalId,
            description:_description,
            deadline:block.timestamp+votingDuration,
            votesFor:0,
            votesAgainst:0,
            executed:false,
            proposer:msg.sender,
            executionData:_calldatas,
            executionTargets:_targets,
            executionTime:0
        });

        emit ProposalCreated(nextProposalId,_description,msg.sender,proposalDepositAmount);
        nextProposalId++;
        return nextProposalId-1;

    }

    function vote(uint256 proposalId,bool support) external{
        Proposal storage proposal=proposals[proposalId];

        require(block.timestamp<proposal.deadline,"Voting period over");
        require(governanceToken.balanceOf(msg.sender)>0,"No governance tokens");
        require(!hasVoted[proposalId][msg.sender],"Already voted");

        uint256 weight=governanceToken.balanceOf(msg.sender);

        if(support){
            proposal.votesFor+=weight;
        }
        else{
            proposal.votesAgainst+=weight;
        }
        hasVoted[proposalId][msg.sender]=true;
        emit Voted(proposalId,msg.sender,support,weight);

    }

    // Decide if the proposal pass or not.
    function finalizeProposal(uint256 proposalId) external{
        Proposal storage proposal=proposals[proposalId];

        require(block.timestamp>=proposal.deadline,"Voting not ended");
        require(!proposal.executed,"Proposal already executed");
        require(proposal.executionTime==0,"Execution time already set");

        uint256 totalSupply=governanceToken.totalSupply();
        uint256 totalVotes=proposal.votesFor+proposal.votesAgainst;
        uint256 quorumNeeded=(totalSupply*quorumPercentage)/100;

        if(totalVotes>=quorumNeeded && proposal.votesFor>proposal.votesAgainst){
            if(timelockDuration>0){
                proposal.executionTime=block.timestamp+timelockDuration;
                emit ProposalTimelockStarted(proposalId,proposal.executionTime);
            }
            else{
                proposal.executed=true;
                emit ProposalExecuted(proposalId,false);
                if(totalVotes<quorumNeeded){
                    emit QuorumNotMet(proposalId,totalVotes,quorumNeeded);
                }
            }
        }


    }

    // Executing the proposal and make the decision real
    function executeProposal(uint256 proposalId) external nonReentrant{
        Proposal storage proposal=proposals[proposalId];

        // require(proposal.timelockEnd>0,"No timelock set");
        require(proposal.executionTime>0&&block.timestamp>=proposal.executionTime,"Timelock not yet expired");
        require(!proposal.executed,"Already executed");

        // Mark the proposal as executed before calling any external contracts.
        // Set executed early to prevent reentrancy.
        proposal.executed=true;

        bool passed=proposal.votesFor>proposal.votesAgainst;

        if(passed){
            for(uint256 i=0;i<proposal.executionTargets.length;i++){
                // Low level call.
                // "proposal.executionData" is abi codes of function executed for target address
                (bool success,bytes memory returnData)=proposal.executionTargets[i].call(proposal.executionData[i]);
                require(success,string(returnData));
            }
            emit ProposalExecuted(proposalId,true);
            governanceToken.transfer(proposal.proposer,proposalDepositAmount);
            emit ProposalDepositRefunded(proposal.proposer,proposalDepositAmount);
        }
        // If proposal failed, no refund of the deposit in this case.
        else{
            emit ProposalExecuted(proposalId,false);
        }

    }


    function getProposalResult(uint256 proposalId) external view returns(string memory){
        Proposal storage proposal=proposals[proposalId];
        require(proposal.executed,"Proposal not yet executed");

        uint256 totalVotes=proposal.votesFor+proposal.votesAgainst;
        uint256 totalSupply=governanceToken.totalSupply();
        uint256 quorumNeeded=(totalSupply*quorumPercentage)/100;

        if(totalVotes<quorumNeeded){
            return "Proposal FAILED-Quorum not met";
        }
        else if(proposal.votesFor>proposal.votesAgainst){
            return "Proposal PASSED";
        }
        else{
            return "Proposal REJECTED";
        }

    }

    function getProposalDetails(uint256 proposalId) external view returns(Proposal memory){
        return proposals[proposalId];

    }

    // function setQuorumPercentage(uint256 _newQuorum) external onlyAdmin{
    //     require(_newQuorum>0&&_newQuorum<=100,"Invalid quorum");
    //     quorumPercentage=_newQuorum;

    // }

}