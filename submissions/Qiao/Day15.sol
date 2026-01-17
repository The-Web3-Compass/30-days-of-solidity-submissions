// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Day 15 creating a gas efficient voting system
contract GasEfficientVoting {
    uint8 public proposalCount;
    mapping(uint8 => Proposal) proposals;
    //mapping(uint8 => uint256) proposalVotes;
    mapping(address => uint256) voterVotes;

    struct Proposal {
        bytes32 name;
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool isActive;
        bool isExecuted;
    }

    event ProposalCreated(uint8 indexed proposalID, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalID);
    event ProposalExecuted(uint8 indexed proposalID);
    
    function createProposal (bytes32 _name, uint32 _duration) external {
        uint8  proposalID = proposalCount;
        require(_duration > 0, "Invalid duration.");
        proposals[proposalID] = Proposal(_name,0,uint32(block.timestamp),uint32(block.timestamp)+_duration,true,false);

        proposalCount++;

        emit ProposalCreated(proposalID, _name);
    }

    function getProposal(uint8 _proposalID) external view returns (
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool isExecuted,
        bool isActive
    ) { 
        require(_proposalID < proposalCount, "Proposal does not exist.");
        Proposal memory p = proposals[_proposalID];
        return (p.name, p.voteCount, p.startTime, p.endTime, p.isExecuted, uint32(block.timestamp) <= p.endTime);

    }

    function execute (uint8 _proposalID) external {
        require(_proposalID < proposalCount, "Proposal does not exist.");
        require(block.timestamp > proposals[_proposalID].endTime, "Voting hasn't ended yet.");
        require(!proposals[_proposalID].isExecuted, "Proposal has already been executed.");
        proposals[_proposalID].isExecuted = true;

        emit ProposalExecuted(_proposalID);
    }

    function hasExecuted (uint8 _proposalID) external view returns (bool) {
        return (proposals[_proposalID].isExecuted);
    }


    function vote (uint8 _proposalID) external {
        require(_proposalID < proposalCount, "Proposal does not exist.");
        require(proposals[_proposalID].isExecuted == false, "Voting has ended.");
        require(uint32(block.timestamp) < proposals[_proposalID].endTime, "Voting has ended.");
        require((voterVotes[msg.sender] & 1 << _proposalID) == 0, "Voter has already voted for this proposal.");

        voterVotes[msg.sender] = voterVotes[msg.sender] | 1 << _proposalID;
        proposals[_proposalID].voteCount ++;

        emit Voted(msg.sender, _proposalID);
    }

    function hasVoted(uint8 _proposalID) external view returns (bool) {
        if ((voterVotes[msg.sender] & 1 << _proposalID) > 0) return false;
        return true; 
    }

}