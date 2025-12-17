// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;
/*
   Build a simple voting system where users can vote on proposals. 
   Your challenge is to make it as gas-efficient as possible. 
   Optimize how you store voter data, handle input parameters, and design functions. 
   You'll learn how `calldata`, `memory`, and `storage` affect gas usage and discover small 
   changes that lead to big savings. 
   It's like designing a voting machine that runs faster and cheaper without losing accuracy.
*/    

contract GasSaver {
    uint8 public proposalCount;
    struct Proposal {
        bytes32 name;
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }
    mapping(address => uint256)private voterRegistry;
    mapping(uint8 => Proposal) public proposals;
    mapping(uint8 =>uint32)public proposalVoterCount;

    event Voted(address indexed voter, uint8 indexed proposalId);   
    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event ProposalExecuted(uint8 indexed proposalId);

    function createProposal(bytes32 _name, uint32 _duration) external{
        require(_duration > 0, "Durations should be more than 0");
        uint8 proposalId = proposalCount;
        proposalCount++;
        Proposal memory newProposal = Proposal({name: _name, voteCount: 0, startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + _duration, executed: false });
        proposals[proposalId] = newProposal;
        emit ProposalCreated(proposalId, _name);
    }

    function hasVoted(address _voter, uint8 _proposalId) external view returns(bool){
        return(voterRegistry[_voter] & (1 << _proposalId) != 0);
    }

    function vote(uint8 _proposalId) external{
        require(_proposalId < proposalCount, "Invalid Proposal");
        uint32 currentTime = uint32(block.timestamp);
        require(currentTime >= proposals[_proposalId].startTime, "Voting has not started");
        require(currentTime <= proposals[_proposalId].endTime, "Voting has ended");
        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << _proposalId;
        require((voterRegistry[msg.sender] & mask) == 0, "Already voted");
        voterRegistry[msg.sender] = voterData | mask;
        proposals[_proposalId].voteCount++;
        proposalVoterCount[_proposalId]++;
        emit Voted(msg.sender, _proposalId);
    }

    function executeProposal(uint8 _proposalId) external{
        require(_proposalId < proposalCount, "Invalid Proposal");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting not ended ");
        require(!proposals[_proposalId].executed, "Already executed");
        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }
      
    function getProposal(uint8 _proposalId) external view returns ( bytes32 name, uint32 voteCount,uint32 startTime,
        uint32 endTime, bool executed, bool active)  {
        require(_proposalId < proposalCount, "Invalid proposal");
        Proposal storage proposal = proposals[_proposalId];
        return ( proposal.name, proposal.voteCount, proposal.startTime, proposal.endTime, proposal.executed,
            (block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime));
    }
}
