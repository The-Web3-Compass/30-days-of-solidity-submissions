// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting{

    uint8 public proposalCount;

    struct  Proposal{
        bytes32 name;
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }
    mapping (uint8 => Proposal) public proposals;
    //投票判断：256位；0表示未投票，1表示投票
    mapping (address=>uint256)private voterRegistry;
    //每个提案的对应投票数量
    mapping (uint8=>uint32)public proposalVoterCount;

    event ProposalCreated(uint8 indexed proposalId,bytes32 name);
    event Voted(address indexed  voter,uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    // 创建提案
    function createProposal(bytes32 _name,uint32 _duration)external {
        require(_duration>0,"Duration must be > 0");

        uint8 proposalId=proposalCount;
        proposalCount++;
        Proposal memory newProposal=Proposal({
            name:_name,
            voteCount:0,
            startTime:uint32(block.timestamp),
            endTime:uint32(block.timestamp+_duration),
            executed:false
        });

        proposals[proposalId]=newProposal;

        emit ProposalCreated(proposalId, _name);
    }
    // 允许用户投票
    function vote(uint8 proposalId) external {
        require(proposalId<proposalCount,"Invalid proposal");
        uint32 curTime=uint32(block.timestamp);
        require(curTime>=proposals[proposalId].startTime,"Voting not started");
        require(curTime<=proposals[proposalId].endTime,"Voting ended");

        uint256 voterData=voterRegistry[msg.sender];
        //检查是否投票，1<<创建一个二进制掩码
        uint256 mask=1<<proposalId;
        //如果AND运算=1的话，说明voterRegistry的对应投票状态为1
        require((voterData&mask)==0,"Already voted");

        voterRegistry[msg.sender]=voterData | mask;

        proposals[proposalId].voteCount++;
        proposalVoterCount[proposalId]++;
        
        emit Voted(msg.sender,proposalId);

    }

    // 允许执行提案
    function executeProposal(uint8 proposalId)external {
        require(proposalId<proposalCount,"Invalid proposal");
        require(uint32(block.timestamp)>=proposals[proposalId].endTime,"Voting not ended");
        require(!proposals[proposalId].executed,"Already executed");

        proposals[proposalId].executed=true;

        emit ProposalExecuted(proposalId);
    }

    // 判断是否投票
    function hasVoted(address voter,uint8 proposalId)external view returns (bool){
        return (voterRegistry[voter]&(1 << proposalId)) != 0;
    }

    //获取投票
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