// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract GasEfficientVoting {
    //太多gas费大家花不起

    uint8 public proposalCount;
    //uint更便宜，proposal也不会有很多
     struct Proposal {
        bytes32 name; 
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime; 
        bool executed; }
        //bytes比string便宜
        //uint32也足够时间可以用到2106年
        mapping(uint8 => Proposal) public proposals;
        mapping(address => uint256) private voterRegistry;
        //没有用嵌套mapping，把所有人的投票压缩在一个投票槽，看是否投票
        mapping(uint8 => uint32) public proposalVoterCount;
        //每个提案有多少人投票
        event ProposalCreated(uint8 indexed proposalId, bytes32 name);
        //用了bytes
        event Voted(address indexed voter, uint8 indexed proposalId);
        event ProposalExecuted(uint8 indexed proposalId);
        //写索引

        function createProposal(bytes32 _name, uint32 duration) external {
        require(duration > 0, "Duration must be > 0");
        //时间要有效
        uint8 proposalId = proposalCount;
        proposalCount++;
        //比push更省fee
        Proposal memory newProposal = Proposal({
            name: _name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + duration,
            executed: false
            
        });
        proposals[proposalId] = newProposal;
        
        emit ProposalCreated(proposalId, _name);
    }
    //创建提案结束
    function vote(uint8 proposalId) external {
        //写投票
        require(proposalId < proposalCount, "Invalid proposal");
        //和以前写的一样
        uint32 currentTime = uint32(block.timestamp);
        //赋予时间
        require(currentTime >= proposals[proposalId].startTime, "Voting is not started");
        require(currentTime <= proposals[proposalId].endTime, "Voting ended");
        //时间限制
        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << proposalId;
        //用mask来看有没有投票，bit操作，用二进制拆分的方法
        require((voterData & mask) == 0, "Already voted");

        voterRegistry[msg.sender] = voterData | mask;
        //把初始值设为1
        proposals[proposalId].voteCount++;
        proposalVoterCount[proposalId]++;
        //计数环节
        emit Voted(msg.sender, proposalId);
    }
    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        require(block.timestamp > proposals[proposalId].endTime, "Voting isnot ended");
        //时间和投票值要求
        require(!proposals[proposalId].executed, "Already executed");
        //应该是未执行的提案
        proposals[proposalId].executed = true;
        //完成上述则标记
        emit ProposalExecuted(proposalId);
        }

        function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        return (voterRegistry[voter] & (1 << proposalId)) != 0;
    }
    //同样的mask用法
    // 位运算遮罩（bit mask），从数据中提取特定位，清零特定位。

    
    function getProposal(uint8 proposalId) external view returns (
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool executed,
        bool active
        //变量插入，一次性返回这些变量
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
            //标志这个活动是否已经结束
        );
    }
}



        

        






