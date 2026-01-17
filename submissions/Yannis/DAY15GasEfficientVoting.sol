// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting {

    uint8 public proposalCount;

    struct Proposal {
        bytes32 name;
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }

    mapping(uint8 => Proposal) public proposals;
    mapping(address => uint256) private voterRegistry;
    mapping(uint8 => uint32) public proposalVoterCount;

    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    function createProposal(bytes32 _name, uint32 duration) external {
        require(duration > 0, "Duration>0");
        
        require(proposalCount < type(uint8).max, "Max proposals reached"); 

        uint8 proposalId = proposalCount;
        proposalCount++;

        Proposal memory newProposal = Proposal({
            name: _name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + duration,
            executed: false
        });

        proposals[proposalId] = newProposal;
        emit ProposalCreated(proposalId, _name);
    }

    function vote(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid");
        uint32 currentTime = uint32(block.timestamp);

        Proposal storage p = proposals[proposalId]; 
        require(currentTime >= p.startTime, "Not started");
        require(currentTime <= p.endTime, "Ended");

        uint256 voterData = voterRegistry[msg.sender]; 
        uint256 mask = uint256(1) << proposalId;

        require((voterData & mask) == 0, "Already voted"); 

        voterRegistry[msg.sender] = voterData | mask;
        p.voteCount++; 
        proposalVoterCount[proposalId]++;

        emit Voted(msg.sender, proposalId);
    }

    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid");
        Proposal storage p = proposals[proposalId];
        require(block.timestamp > p.endTime, "Voting not ended");
        require(!p.executed, "Already executed");

        p.executed = true;
        emit ProposalExecuted(proposalId);
    }

    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        
        return (voterRegistry[voter] & (uint256(1) << proposalId)) != 0;
    }

    function getProposal(uint8 proposalId) external view returns (
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool executed,
        bool active
    ) {
        require(proposalId < proposalCount, "Invalid");

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
}
