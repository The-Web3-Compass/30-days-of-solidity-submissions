// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasSaveVoting {

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

    error DurationZero();
    error ProposalNotFound();
    error VotingNotStarted();
    error VotingEnded();
    error AlreadyVoted();
    error InvalidProposal();
    error VotingNotEnded();
    error AlreadyExecuted();

    function createProposal(bytes32 name, uint32 duration) external {
        if (duration == 0) revert DurationZero();

        uint8 proposalId = proposalCount;

        unchecked {
            proposalCount++;
        }

        Proposal storage newProposal = proposals[proposalId];
        newProposal.name = name;
        newProposal.voteCount = 0;
        newProposal.startTime = uint32(block.timestamp);
        newProposal.endTime = uint32(block.timestamp) + duration;
        newProposal.executed = false;

        emit ProposalCreated(proposalId, name);
    }

    function vote(uint8 proposalId) external {
        if (proposalId >= proposalCount) revert ProposalNotFound();

        Proposal storage proposal = proposals[proposalId];
        uint32 currentTime = uint32(block.timestamp);
        
        if (currentTime < proposal.startTime) revert VotingNotStarted();
        if (currentTime > proposal.endTime) revert VotingEnded();

        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << proposalId;
        if ((voterData & mask) != 0) revert AlreadyVoted();
        
        voterRegistry[msg.sender] = voterData | mask;

        unchecked {
            proposal.voteCount++;
            proposalVoterCount[proposalId]++;
        }

        emit Voted(msg.sender, proposalId);
    }

    function executeProposal(uint8 proposalId) external {
        if (proposalId >= proposalCount) revert InvalidProposal();
        
        Proposal storage proposal = proposals[proposalId];
        if (uint32(block.timestamp) <= proposal.endTime) revert VotingNotEnded();
        if (proposal.executed) revert AlreadyExecuted();

        proposal.executed = true;
        
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
        if (proposalId >= proposalCount) revert InvalidProposal();

        Proposal storage proposal = proposals[proposalId];
        uint32 currentTime = uint32(block.timestamp);

        return (
            proposal.name,
            proposal.voteCount,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            (currentTime >= proposal.startTime && currentTime <= proposal.endTime)
        );
    }
}