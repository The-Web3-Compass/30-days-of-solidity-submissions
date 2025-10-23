// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficient{
    uint8 public proposalCount;

    struct Proposal{
        bytes32 name;
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }

    mapping(uint8 => Proposal) public proposals;

    mapping(address => uint256)public voterRegistry;    //8bits,each bits is one proposal situation

    mapping(uint8 => uint32) public proposalVoterCount;  

    //Events
    event ProposalCreated(uint8 indexed proposalId,bytes32 Proposalname);
    event Voted(address indexed _addr,uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);


    function createProposal(bytes32 _name,uint32 _duration)external{
        uint8 proposalId = proposalCount++;

        Proposal memory proposal = Proposal({
            name: _name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + _duration,
            executed: false
            });

        proposals[proposalId] = proposal;
        emit ProposalCreated(proposalId, _name);
    }

    function vote(uint8 _proposalId) external{
        require(_proposalId < proposalCount,"Invalid");
        uint32 currentTime = uint32(block.timestamp);
        require(currentTime >= proposals[_proposalId].startTime,"not start yet");
        require(currentTime <= proposals[_proposalId].endTime,"not end yet");

        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << _proposalId;
        require((voterData & mask) == 0, "already voted");

        voterRegistry[msg.sender] = voterData | mask;
        
        
        proposals[_proposalId].voteCount++;
        proposalVoterCount[_proposalId]++;
        
        emit Voted(msg.sender, _proposalId);
    }

    function executeProposal(uint8 _proposalId) external{
        require(_proposalId < proposalCount,"Invalid");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting not ended");
        require(!proposals[_proposalId].executed, "Already executed");
        
        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
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