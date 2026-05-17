// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleVoting {
    
    uint256 public proposalCount;
    
    struct Proposal {
        string name;
        uint256 voteCount;
        uint256 startTime;
        uint256 endTime;
        bool executed;
    }
    
    Proposal[] public proposals;
    
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    
    mapping(uint256 => uint256) public proposalVoterCount;
    
    event ProposalCreated(uint256 indexed proposalId, string name);
    event Voted(address indexed voter, uint256 indexed proposalId);
    event ProposalExecuted(uint256 indexed proposalId);
    
    function createProposal(string memory name, uint256 duration) external {
        require(duration > 0, "Duration must be greater than 0");
        
        uint256 proposalId = proposals.length;
        
        Proposal memory newProposal = Proposal({
            name: name,
            voteCount: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            executed: false
        });
        
        proposals.push(newProposal);
        proposalCount++;
        
        emit ProposalCreated(proposalId, name);
    }
    
    function vote(uint256 proposalId) external {
        require(proposalId < proposals.length, "Invalid proposal");
        
        uint256 currentTime = block.timestamp;
        require(currentTime >= proposals[proposalId].startTime, "Voting not started");
        require(currentTime <= proposals[proposalId].endTime, "Voting ended");
        require(!hasVoted[msg.sender][proposalId], "Already voted");
        
        hasVoted[msg.sender][proposalId] = true;
        proposals[proposalId].voteCount++;
        proposalVoterCount[proposalId]++;
        
        emit Voted(msg.sender, proposalId);
    }
    
    function executeProposal(uint256 proposalId) external {
        require(proposalId < proposals.length, "Invalid proposal");
        require(block.timestamp > proposals[proposalId].endTime, "Voting not ended");
        require(!proposals[proposalId].executed, "Already executed");
        
        proposals[proposalId].executed = true;
        
        emit ProposalExecuted(proposalId);
    }
    
    function checkVoteStatus(address voter, uint256 proposalId) external view returns (bool) {
        return hasVoted[voter][proposalId];
    }
    
    function getProposalInfo(uint256 proposalId) external view returns (
        string memory name,
        uint256 voteCount,
        uint256 startTime,
        uint256 endTime,
        bool executed,
        bool active
    ) {
        require(proposalId < proposals.length, "Invalid proposal");
        
        Proposal storage proposal = proposals[proposalId];
        
        return (
            proposal.name,
            proposal.voteCount,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            (block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime)
        );
    }
    
    function getAllProposals() external view returns (Proposal[] memory) {
        return proposals;
    }
    
    function getActiveProposals() external view returns (Proposal[] memory) {
        uint256 count = 0;
        
        for(uint256 i = 0; i < proposals.length; i++) {
            if(block.timestamp >= proposals[i].startTime && block.timestamp <= proposals[i].endTime) {
                count++;
            }
        }
        
        Proposal[] memory activeProposals = new Proposal[](count);
        uint256 index = 0;
        
        for(uint256 i = 0; i < proposals.length; i++) {
            if(block.timestamp >= proposals[i].startTime && block.timestamp <= proposals[i].endTime) {
                activeProposals[index] = proposals[i];
                index++;
            }
        }
        
        return activeProposals;
    }
}