// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GasEfficientVoting{

    // 2^8 = 256 
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

    event ProposalCreated(uint8 indexed proposalId,bytes32 name);
    event Voted(address indexed voter,uint8 indexed proposalID);
    event ProposalExecuted(uint8 indexed proposalId);

    function createProposal(bytes32 _name,uint32 _duration)external {
        uint8 proposalId = proposalCount;
        proposalCount++;

        proposals[proposalId] = Proposal ({
            name:_name,
            voteCount:0,
            startTime:uint32(block.timestamp),
            endTime:uint32(block.timestamp+_duration),
            executed:false
            }
        );

        emit ProposalCreated(proposalId, _name);
    }

    function vote(uint8 _proposalId)external {
        require(_proposalId<proposalCount,"Invalid proposal");
        uint32 currentTime = uint32(block.timestamp);
        require(currentTime>proposals[_proposalId].startTime,"Voting not started");
        require(currentTime<proposals[_proposalId].endTime,"Voting ended");

        uint256 voteData = voterRegistry[msg.sender];
        uint256 mask = 1 << voteData;
        require(voteData & mask == 0,"Already voted");

        proposals[_proposalId].voteCount++;
        proposalVoterCount[_proposalId]++;

        emit Voted(msg.sender, _proposalId);

    }

    function executeProposal(uint8 _proposalId) external {
        require(block.timestamp > proposals[_proposalId].endTime, "Voting not ended");
        require(_proposalId < proposalCount, "Invalid proposal");
        require(!proposals[_proposalId].executed, "Already executed");

        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }

    function hasVoted(address voter, uint8 _proposalId)external view returns(bool){
        return(voterRegistry[voter] & (1<<_proposalId) !=0);
    }

    function getProposal(uint8 proposalId)external view returns(
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool executed,
        bool active
    ){
        return (
            proposals[proposalId].name,
            proposals[proposalId].voteCount,
            proposals[proposalId].startTime,
            proposals[proposalId].endTime,
            proposals[proposalId].executed,
            (block.timestamp>=proposals[proposalId].startTime && block.timestamp<=proposals[proposalId].endTime)
        );
    }
}