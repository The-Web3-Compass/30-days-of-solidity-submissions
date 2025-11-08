//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting{

    uint8 public ProposalCount;
    struct Proposal{
        bytes32 name;
        uint32 VoteCount;
        uint32 StartTime;
        uint32 EndTime;
        bool executed;

    }

    mapping(uint8 => Proposal) public proposals;
    mapping(address => uint256) private VoterRegistry;
    mapping(uint8 => uint32) public ProposalVoterCount;

    event ProposalCreated(uint8 indexed ProposalId, bytes32 name);
    event Voted(address indexed Voter, uint8 indexed ProposalId);
    event ProposalExecuted(uint8 indexed ProposalId);


    function CreateProposal(bytes32 _name, uint32 duration) external{
        require(duration > 0, "Durations should be more than 0");
        uint8 ProposalId = ProposalCount;
        ProposalCount++;
        Proposal memory NewProposal = Proposal({
            name: _name,
            VoteCount: 0,
            StartTime: uint32(block.timestamp),
            EndTime: uint32(block.timestamp + duration),
            executed: false
        });
        proposals[ProposalId] = NewProposal;
        emit ProposalCreated(ProposalId, _name);

    }

    function Vote(uint8 ProposalId) external{
        require(ProposalId < ProposalCount, "Invalid proposal");
        uint32 CurrentTime = uint32(block.timestamp);
        require(CurrentTime >= proposals[ProposalId].StartTime, "Voting has not started");
        require(CurrentTime <= proposals[ProposalId].EndTime, "Voting has ended");

        uint256 VoteData = VoterRegistry[msg.sender];
        uint256 mask = 1 << ProposalId;
        require((VoterRegistry[msg.sender] & mask) == 0, "Already voted");
        VoterRegistry[msg.sender] = VoteData | mask;
        proposals[ProposalId].VoteCount++;
        ProposalVoterCount[ProposalId]++;

        emit Voted(msg.sender, ProposalId);

    }

    function ExecuteProposal(uint8 ProposalId) external{
        require(ProposalId < ProposalCount, "Invalid proposal");
        require(block.timestamp > proposals[ProposalId].EndTime, "Voting not ended");
        require(!proposals[ProposalId].executed, "Already executed");
        proposals[ProposalId].executed = true;
        emit ProposalExecuted(ProposalId);

    }

    function HasVoted(address Voter, uint8 ProposalId) external view returns(bool){
        return (VoterRegistry[Voter] & (1<< ProposalId) != 0);

    }

    function GetProposal(uint8 ProposalId) external view returns(
        bytes32 name,
        uint32 VoteCount,
        uint32 StartTime,
        uint32 EndTime,
        bool executed,
        bool active
    ){
        require(ProposalId < ProposalCount, "Invalid proposal");

        Proposal storage proposal = proposals[ProposalId];
        return(
            proposal.name,
            proposal.VoteCount,
            proposal.StartTime,
            proposal.EndTime,
            proposal.executed,
            (block.timestamp >= proposal.StartTime && block.timestamp <= proposal.EndTime)
        );
        
    }

}
