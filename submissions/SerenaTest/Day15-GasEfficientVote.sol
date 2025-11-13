//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract GasEfficientVote{
    //创建一个节省GAS的投票合约
    //提案结构体
    struct Proposal{
        bytes32 name;//使用byte32代替string  注意调试时需要将字符串转换成byte32
        uint32 startTime;
        uint32 endTime;
        uint32 voteCount;  //票数
        bool executed;   //是否执行
    }

    uint8 public proposalCount; //提案总数

    mapping(uint8 => Proposal) public proposals; //提案数（ID+1）到提案的映射
    mapping(address => uint256) public voteRegistry;  //投票注册表  每个投票者对于每个提案（0-255）的投票情况
    mapping(uint8 => uint32) public proposalVoteCount;  //每个提案的票数

    event Create(uint8 indexed proposalId,bytes32 name);
    event Vote(address indexed voter,uint8 indexed proposalId);
    event Execute(uint8 indexed proposalId);

    function create(bytes32 name,uint32 duration) external{
        require(duration > 0,"Incorrect duration!");

        proposals[proposalCount] = Proposal({
            name : name,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + duration,
            voteCount : 0,
            executed : false
        });

        emit Create(proposalCount,name);

        proposalCount ++;
    }

    function vote(uint8 proposalId) public{
        require(proposalId < proposalCount,"Invalid id!");
        require(block.timestamp <= proposals[proposalId].endTime,"The proposal is over");
        require(block.timestamp >= proposals[proposalId].startTime,"Not start yet");
        uint256 msk = 1 << proposalId;
        require((voteRegistry[msg.sender] & msk) == 0,"Already voted"); //利用位移判断是否已经投票
        voteRegistry[msg.sender] |= msk; //对应位置即对应提案标记为1表示已经投票
        proposals[proposalId].voteCount ++;
        proposalVoteCount[proposalId] ++;
        emit Vote(msg.sender,proposalId);
    }

    function execute(uint8 proposalId) public {
        require(proposalId < proposalCount,"Invalid id!");
        require(block.timestamp > proposals[proposalId].endTime,"Voting hasnot end yet");
        require(!proposals[proposalId].executed,"The proposal already executed!");
        proposals[proposalId].executed = true;
        emit Execute(proposalId);   //没有设置执行的票数条件
    }

     //投票注册表逻辑
    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        return (voteRegistry[voter] & (1 << proposalId)) != 0;
    }

    //获取提案信息
    function getProposal(uint8 proposalId) external view returns (
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool executed,
        bool active  //加一个状态
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