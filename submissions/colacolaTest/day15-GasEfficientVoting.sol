// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting{
    uint8 public proposalCount;

    struct Proposal{
        bytes32 name;
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }

    mapping(uint8 => Proposal) public proposals;
    mapping(address => uint256) private voterRegistry;

    event ProposalCreated(uint8 indexed proposalID, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalID);
    event ProposalExecuted(uint8 indexed proposalID);

     function createProposal(bytes32 _name, uint32 duration) external {
        require(duration > 0, "Duration must be > 0");
        require(proposalCount < 255, "Too many proposals");

        uint8 proposalID = proposalCount;
        unchecked { proposalCount++; }
    
        Proposal memory newProposal = Proposal ({
        name: _name,
        voteCount: 0,
        startTime: uint32(block.timestamp),
        endTime: duration + uint32(block.timestamp),
        executed: false
        });

        proposals[proposalID] = newProposal;

        emit  ProposalCreated(proposalID, _name);
    }
