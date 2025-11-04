// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting{

    uint8 public proposalCount;
    struct Proposal{
        bytes32  name;//bytes3替代string
        uint32 voteCount;//uint32替代uint256
        uint32 startTime;
        uint32 endTime;
        bool executed;

    }

    //Proposal[] public proposals;
    //mapping(address=>mapping(uint256=>bool)) public hasVoted;

    mapping(uint8=>Proposal)public proposals;
    mapping(address=>uint256)public voterRegistry;
    mapping(uint8=>uint32)public proposalVoterCount;

    event proposalCreated(uint8 indexed proposalId,bytes32 indexed name);
    event Voted(address indexed voter,uint8 indexed proposalId);
    event proposalExecuted(uint8 indexed proposalId);

    function creatProposal(bytes32 name,uint32 duration) external{
        uint8 proposalId= proposalCount;
        proposalCount++;
        require(duration>0,"Duration must be > 0");


        //proposals.push(Proposal({
            //name:name,
            //voteCount:0,
            //startTime:block.timestamp,
            //endTime:block.timestamp+duration,
            //executed:false
       // }));
        Proposal memory newProposal = Proposal({
            name: name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp + duration),
            executed: false
        });

        proposals[proposalId] = newProposal;
        
        emit proposalCreated(proposalId, name);
    }


    //function vote(uint256 proposalId)public{
        //Proposal storage proposal=proposals[proposalId];
        //require(block.timestamp<proposal.endTime,"too late");
        //require(block.timestamp>proposal.startTime,"too early");
        //require(!hasVoted[msg.sender][proposalId],"already voted");
        //hasVoted[msg.sender][proposalId]=true;
        //proposal.voteCount++;

    //}

      
function vote(uint8 proposalId) external {
    require(proposalId < proposalCount, "Invalid proposal");

    uint32 currentTime = uint32(block.timestamp);
    require(currentTime >= proposals[proposalId].startTime, "Voting not started");
    require(currentTime <= proposals[proposalId].endTime, "Voting ended");

    uint256 voterData = voterRegistry[msg.sender];
    uint256 mask = 1 << proposalId;
    require((voterData & mask) == 0, "Already voted");

    voterRegistry[msg.sender] = voterData | mask;

    proposals[proposalId].voteCount++;
    proposalVoterCount[proposalId]++;

    emit Voted(msg.sender, proposalId);
}

    function executedPropsal(uint8 proposalId) public{
        Proposal storage proposal=proposals[proposalId];
        require(block.timestamp>proposal.endTime,"too early");
        require(!proposal.executed,"already executed");
        require(proposal.voteCount>0,"no votes");
        proposal.executed=true;
    }

}