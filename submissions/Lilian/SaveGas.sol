// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting {
    uint8 public propolsalcouont;//使用uint8而不是uint256

    struct Propolsal{
        byte32 name;
        uint32 votecount;
        uint32 startTime;
        uint32 endTime;
        bool executed;//打包在同一槽位
    }

    mapping(uint8=>propolsal)public proposal;//使用映射来存储

    mapping (address=>uint256)private voterRegistry;//压缩到uint256中
    mapping (uint8=>uint32)public proposalvotercount;//跟踪有多少人投了票

    event proposalcreated (uint8 indexed proposalID,byte32 name);
    event Voted(address indexed  voter,uint8 indexed proposalID);
    event Propasalexecuted (uint8 indexed proposalID);//过滤日志

    function createProposal (byte32 name,uint32 duration)external {
        require(duration>0,"Duration must be > 0");//确保持续时间不为零

        uint8 proposalID = proposalcount;//用计时器而不是推送到数组
        proposalCount++;

        Proposal memory newProposal = Proposal({
            name:name,
            votecount:0,
            startTime:uint32(block.timestamp),
            endTime:uint32(block.timestamp+duration),
            executed:false
        });

        proposals[proposalID]=newProposal;
        emit proposalcreated(proposalID, name);
    }
    function vote(uint8 proposalID)external {
        require(proposalID<proposalCount,"Invalid Proposal");//ID在有效范围内

        uint32 currentTime=uint32 (block.timestamp);
        require(currentTime>=Propolsals[proposalID].startTime,"Voted not started");
        require(currentTime<=Proposals[proposalID].endTime,"Voted not ended");

        uint256 voterData =voterRegistry[msg.sender];
        uint256 mask =1 <<proposalID;

        require((voterData&mask)==0,"Already voted");//检查是否投票

        voterRegistry [msg.sender] = voterData|mask;

        proposals[proposalID].votecount++;
        proposalvotercount[proposalID]++;

        emit Voted(proposalvoted, proposalID);
    }
    function executeProposal(uint8 proposalID)external {
        require(proposalID<proposalvotercount,"Invalid Proposal");
        require(block.timestamp>proposals.[proposalID]endTime,"Not ended");
        require(!Propolsals[proposalID].executed,"Already executed");

        proposals[proposalID].executed=true;

        emit proposalExecuted(proposalID);//执行提案
    }
    function hasVoted(address voter,uint8 proposalID)external view returns (bool){
        return (voterRegistry[voter]&(1<<proposalID))!=0;
    }

    function getproposal (uint8 proposalID)external view returns (
        byte32 name,
        uint32 votecount,
        uint32 startTime,
        uint32 endTime,
        bool executed
    ){
        require(proposalID<propolsalcouont,"Invalid proposal");
        proposal storage Propolsal=proposals [proposalID];
        return (
            proposal.name,
            proposal.voteCount,
            proposal.startTime,
            propolsal.endTime,
            Propolsal.executed,
             (block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime)
        );

    }

    
}