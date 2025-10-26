// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting {
    uint8 public proposalCount;
     
    struct Proposal {
        bytes32 name; // Fixed-size, cheaper than string
        uint32 voteCount; // Enough for 4.2 billion votes, saves gas
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }

    mapping(uint8 => Proposal) public proposals;
    mapping(address => uint256) private voterRegistry;
    mapping(address => mapping(uint8 => bool)) voted;
    mapping(uint8 => uint32) public proposalVoterCount;

    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

  
    function createProposal(bytes32 name, uint32 duration) external {
        require(duration > 0, "Duration must be > 0");

        uint8 proposalId = proposalCount;
        proposalCount++;

        Proposal memory newProposal = Proposal({
            name: name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + duration,
            executed: false
        });

        proposals[proposalId] = newProposal;

        emit ProposalCreated(proposalId, name);
    }

  
    function vote(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");

        uint32 currentTime = uint32(block.timestamp);
        require(currentTime >= proposals[proposalId].startTime, "Voting not started");
        require(currentTime <= proposals[proposalId].endTime, "Voting ended");

        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << proposalId; // 1 << proposalId creates a binary mask like 000100 (if proposalId is 2).
        require((voterData & mask) == 0, "Already voted"); // Bitwise OR sets the bit at position proposalId to 1, marking the vote.

        voterRegistry[msg.sender] = voterData | mask;

        proposals[proposalId].voteCount++;
        proposalVoterCount[proposalId]++;

        emit Voted(msg.sender, proposalId);
    }

  
    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        require(block.timestamp > proposals[proposalId].endTime, "Voting not ended");
        require(!proposals[proposalId].executed, "Already executed");

        proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);
    }


    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        return (voterRegistry[voter] & (1 << proposalId)) != 0;
    }

      
    function getProposal(uint8 proposalId) external view returns (
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool executed,
        bool active
    ) {
        require(proposalId < proposalCount, "Invalid proposal");

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

