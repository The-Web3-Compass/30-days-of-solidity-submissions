pragma solidity ^0.8.10;
contract GasEfficientVoting{
    struct Proposals{
        bytes32 name;
        uint32 startTime;
        uint32 endTime;
        bool isRegulated;
        uint8 voteCount;
    }
    mapping(address=>uint256)UserVotings;
    mapping(uint8 =>Proposals)proposalArray;
    uint8 proposalCount=0;
    mapping(uint8=>uint32)VotesPerProposal;
    event ProposalCreated(bytes32 name,uint32 endTime);
    event VotingToProposal(uint8 ProposalID,uint32 currentTime);
    function createProposal(bytes32 _name,uint32 duration)public{
        Proposals memory newProposal=Proposals({name:_name,startTime:uint32(block.timestamp),endTime:uint32(block.timestamp)+duration,isRegulated:false,voteCount:0});
        emit ProposalCreated(_name, uint32(block.timestamp+duration));
        proposalArray[proposalCount]=newProposal;
        proposalCount++;
    }
    function vote(uint8 ProposalID)external{
        require(proposalCount>ProposalID,"Wrong Proposal ID");
        uint32 currentTime=uint32(block.timestamp);
        require(currentTime<proposalArray[ProposalID].endTime,"Time End");
        uint256 voteData=UserVotings[msg.sender];
        uint256 mask=1<<ProposalID;
        require(mask & voteData==0,"Already Voted");
        UserVotings[msg.sender]=voteData | mask;
        proposalArray[ProposalID].voteCount+=1;
        VotesPerProposal[ProposalID]+=1;
        emit VotingToProposal(ProposalID,currentTime);
    }

    function hasVoted(address voter, uint8 ProposalId)public view returns(bool){
        return ((UserVotings[voter])&(1<<ProposalId)==0);
    }
    function getProposalDatas(uint8 PID)public returns( bytes32 name,
        uint32 startTime,
        uint32 endTime,
        bool isRegulated,
        uint8 voteCount ,
        bool active) {
            uint32 currentTime=uint32(block.timestamp);
            bool isActive=false;
            if(currentTime<proposalArray[PID].endTime){
                isActive=true;
            }
            Proposals storage newProposal=proposalArray[PID];
            return(newProposal.name,newProposal.startTime,newProposal.endTime,newProposal.isRegulated,newProposal.voteCount,isActive);
    }
}