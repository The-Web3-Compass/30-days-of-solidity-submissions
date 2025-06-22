// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GasEfficientVoting{

    uint8 public proposalCount;

    struct Proposal {
        // Use bytes32 instead of string to save gas
        bytes32 name;
        // Supports up to ~4.3 billion votes
        uint32 voteCount;
        // Unix timestamp (supports dates until year 2106)
        uint32 startTime;
        uint32 endTime;
        bool executed;

    }

    // key:proposalId
    mapping(uint8 => Proposal)public proposals;

    mapping(address => uint256)private voterRegistry;

    mapping(uint8 => uint32) private proposalVoteCount;

    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);
    

    function createProposal(bytes32 name, uint32 startTime,uint32 endTime) public return(uint8){
        require(startTime > 0 && endTime > 0, "Duration must be > 0");
        require(startTime < endTime,"Start time should smaller than end time");
        require(startTime > block.timestamp , "Start time should bigger than now");

        // Increment counter - cheaper than .push() on an array
        uint8 proposalId = proposalCount;
        proposalCount++;

        Proposal memory newProposal = Proposal({
            name: name,
            startTime: startTime,
            endTime: endTime,
            unit32: 0,
            bool: false;
        })

        // propoalId could be insteaded by UUID
        proposals[proposalId] = newProposal;

        emit ProposalCreated(proposalId, name);

        return proposalId;

    }

    function vote(uint8 proposalId) external {
        require(proposals[proposalId] != 0,"Invalid proposal");
        uint32 currentTime = uint32(block.timestamp);
        require(currentTime >= proposals[proposalId].startTime & currentTime <= proposals[proposalId].endTime,
         "It's not time to vote ");
        require(voterRegistry[msg.sender] == 0,"Already voted");

        proposals[proposalId].voteCount++;
        proposalVoterCount[proposalId]++;
        
        emit Voted(msg.sender, proposalId);

    }


    function executeProposal(uint8 proposalId) external {
        require(proposals[proposalId] != 0,"This proposal doesn't exist");
        require(block.timestamp > proposals[proposalId].endTime, "Voting not ended");
        require(!proposals[proposalId].executed, "Already executed");
        
        proposals[proposalId].executed = true;
        
        emit ProposalExecuted(proposalId);
    
    }

    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        return (voterRegistry[voter] & (1 << proposalId)) != 0;
    }


    
    function getProposal(uint8 proposalId) external view returns (Proposal) {
        require(proposals[proposalId] != 0, "Invalid proposal");
        
        Proposal storage proposal = proposals[proposalId];
        
        return proposal;
    }



}