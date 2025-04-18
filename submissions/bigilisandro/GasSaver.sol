// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract GasEfficientVoting {
    // Struct to store proposal data efficiently
    struct Proposal {
        string description;
        uint256 voteCount;
        bool executed;
        uint256 endTime;
    }

    // Struct to store voter data efficiently
    struct Voter {
        bool hasVoted;
        uint8 voteChoice; // 1 for yes, 2 for no
    }

    // State variables
    address public owner;
    Proposal[] public proposals;
    mapping(uint256 => mapping(address => Voter)) public voters;
    uint256 public proposalCount;

    // Events
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 endTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint8 voteChoice);
    event ProposalExecuted(uint256 indexed proposalId);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < proposalCount, "Proposal does not exist");
        _;
    }

    modifier notVoted(uint256 _proposalId) {
        require(!voters[_proposalId][msg.sender].hasVoted, "Already voted");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(block.timestamp < proposals[_proposalId].endTime, "Proposal has ended");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Create a new proposal
    function createProposal(
        string calldata _description,
        uint256 _durationInDays
    ) external onlyOwner returns (uint256) {
        require(_durationInDays > 0, "Duration must be greater than 0");
        
        uint256 proposalId = proposalCount++;
        proposals.push(Proposal({
            description: _description,
            voteCount: 0,
            executed: false,
            endTime: block.timestamp + (_durationInDays * 1 days)
        }));

        emit ProposalCreated(proposalId, _description, block.timestamp + (_durationInDays * 1 days));
        return proposalId;
    }

    // Cast a vote
    function castVote(uint256 _proposalId, uint8 _voteChoice) 
        external 
        proposalExists(_proposalId)
        notVoted(_proposalId)
        proposalActive(_proposalId)
    {
        require(_voteChoice == 1 || _voteChoice == 2, "Invalid vote choice");
        
        voters[_proposalId][msg.sender] = Voter({
            hasVoted: true,
            voteChoice: _voteChoice
        });

        if (_voteChoice == 1) {
            proposals[_proposalId].voteCount++;
        }

        emit VoteCast(_proposalId, msg.sender, _voteChoice);
    }

    // Get proposal details
    function getProposal(uint256 _proposalId) 
        external 
        view 
        proposalExists(_proposalId)
        returns (
            string memory description,
            uint256 voteCount,
            bool executed,
            uint256 endTime
        )
    {
        Proposal memory proposal = proposals[_proposalId];
        return (
            proposal.description,
            proposal.voteCount,
            proposal.executed,
            proposal.endTime
        );
    }

    // Check if a user has voted
    function hasVoted(uint256 _proposalId, address _voter) 
        external 
        view 
        proposalExists(_proposalId)
        returns (bool)
    {
        return voters[_proposalId][_voter].hasVoted;
    }

    // Get voting results
    function getVotingResults(uint256 _proposalId) 
        external 
        view 
        proposalExists(_proposalId)
        returns (uint256 yesVotes, uint256 totalVotes)
    {
        return (proposals[_proposalId].voteCount, proposalCount);
    }
}
