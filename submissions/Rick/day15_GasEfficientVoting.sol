// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    gas 优化策略
    1.string -> bytes32，固定长度保存数据
    2.uint -> uint32 减少存储位宽
    3.struct 数组改为 mapping，避免动态数据结构
    4.时间比较缩小为uint32 
    5.投票记录 256个bool ，转化为uint256 中256个bit
    6.event添加indexed 节省日志检索
*/
contract GasEfficientVoting {

    // 标识活动的id 0~255 足够标识活动数量
    uint8 private proposalIdSeral;

    struct Proposal {
        // 投票活动名称
        bytes32 name;
        // 投票次数
        uint32 voteCount;
        // 开始时间
        uint32 startTime;
        // 结束时间
        uint32 endTime;
        // 投票活动是否已经关闭
        bool executed;
    }
    // proposalId  -> Proposal
    mapping (uint8 => Proposal) public ProposalMap;

    //每个用户投票记录 uint256对应proposalIdSeral中可创建的256个活动，每个bit位表示对应活动是否投票
    mapping(address => uint256) private voterRegistry;

    //每个活动投票次数
    mapping (uint8=>uint32) public proposalVoterCount;

    // 活动创建
    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    // 用户投票
    event Voted(address indexed voter, uint8 indexed proposalId);
    // 活动关闭
    event ProposalExecuted(uint8 indexed proposalId);
    
    // 创建活动
    function createProposal(bytes32 _name , uint32 duration) external {
        require(duration > 0 ,"duration must > 0");

        Proposal memory pro = Proposal({
            name : _name,
            voteCount : 0,
            startTime : uint32(block.timestamp),
            endTime : uint32(block.timestamp) + duration,
            executed : false
        });

        uint8 proposalId = proposalIdSeral;
        proposalIdSeral++;

        ProposalMap[proposalId] = pro;

        emit ProposalCreated(proposalId, _name);
    }

    // 投票
    function vote(uint8 proposalId) external {
        require(proposalId < proposalIdSeral ,"proposalId not created");
        
        uint32 nowTime = uint32(block.timestamp);
        require(nowTime >= ProposalMap[proposalId].startTime , "must starrt");
        require(nowTime <= ProposalMap[proposalId].endTime , "must not end");

        uint256 voterData = voterRegistry[msg.sender];
        // 将256位二进制数字 在proposalId位更新为 1
        uint256 mask = 1 << proposalId;
        /*
            按位与
            mask中 proposalId位为1
            voterData & mask  按位与 有false为false，有0为0  有true为true，1 1为1
            如果voterData & mask == 0 表示voterData中proposalId位为0，表示没有投票过
            如果voterData & mask == 1 表示voterData中proposalId位为1，表示已经投票过

            按位或  |
            FF为F 00为0，有T为T 有1为1
            voterData | mask 将所有活动的投票记录合到同一个uint256中
        */
        require((voterData & mask) == 0,"already voted");

        voterRegistry[msg.sender] = voterData | mask;

        ProposalMap[proposalId].voteCount ++;
        proposalVoterCount[proposalId] ++;

        emit Voted(msg.sender, proposalId);
    }

    // 活动关闭
    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalIdSeral ,"proposalId not created");
        require(block.timestamp > ProposalMap[proposalId].endTime, "Voting not ended");
        require(!ProposalMap[proposalId].executed, "Already executed");
        

        ProposalMap[proposalId].executed = true;

        emit ProposalExecuted(proposalId);
    }

    // 查询某用户是否已经投票
    // 判断逻辑同上
    function hasVoted(address addr , uint8 proposalId) external returns (bool){
        return voterRegistry[addr] & (1 << proposalId) != 0;
    }

    //获取活动信息 
    function getProposal(uint8 proposalId) external view returns (
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool executed,
        bool active
    ) {
        require(proposalId < proposalIdSeral, "Invalid proposal");
        
        Proposal storage proposal = ProposalMap[proposalId];
        
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