// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting{
    
    uint8 public proposalCount;//更有限的提案数量，可以表示256个提案
    
    struct Proposal {
        // string name;
        bytes32 name;

        // uint256 voteCount;
        // uint256 startTime;
        // uint256 endTime;

        uint32 voteCount;//支持 42 亿次投票
        uint32 startTime;
        uint32 endTime;

        bool executed;
    }

    //Proposal[] public proposals;
    // 映射比数组节省gas，提案详细信息
    mapping(uint8 => Proposal) public proposals;
    //对不同提案的投票数量信息
    mapping(uint8 => uint32) public proposalVoteCount;

    // 对提案ID进行投票了吗？改成用位运算投票，有标号就代表投了
    //mapping(address => mapping(uint => bool)) public hasVoted;
    mapping (address => uint256 ) private voteRegistry;

    

    event ProposalCreated(uint8 indexed _proposalID, bytes32 name);
    event Voted(address indexed _voter,uint8 indexed _proposalID);
    event ProposalExecuted(uint8 indexed _proposalID);


    function createProposal(bytes32 _name, uint32 _duration) public {
        require(_duration>0, " duration must be > 0");
        uint8 proposalID = proposalCount;
        proposalCount++;//下一个提案的序号

        Proposal memory newProposal = Proposal({
            name:_name,
            voteCount:0,
            startTime: uint32(block.timestamp),
            endTime:uint32(block.timestamp+_duration),
            executed:false
        });

        proposals[proposalID]  = newProposal;
        emit ProposalCreated(proposalID, _name);//创建一个提案：标号+自定义名字
    }

    function vote(uint8 _proposalId) public {
        require(_proposalId<proposalCount, "Invalid proposal");

        uint32 currentTime = uint32(block.timestamp);//如果重复使用就需要压入栈，防止浪费资源

        require(currentTime >= proposals[_proposalId].startTime, "Too early");
        require(currentTime <= proposals[_proposalId].endTime, "Too late");


        uint256 voterData = voteRegistry[msg.sender];
        uint256 mask = 1 << _proposalId;//代表第i个提案被投票过了，从右往左数
        //验证是否该用户对提案ID投过票
        require((voterData & mask)==0, "has voted");

        voteRegistry[msg.sender]=voterData|mask;//投票操作
        
        proposalVoteCount[_proposalId]++;
        proposals[_proposalId].voteCount++;
        emit Voted(msg.sender, _proposalId);
    }

    function executeProposal(uint8 _proposalId) public {
        require(_proposalId<proposalCount, "Invalid proposal");

        uint32 currentTime = uint32(block.timestamp);//如果重复使用就需要压入栈，防止浪费资源

        require(currentTime >= proposals[_proposalId].startTime, "Too early");
        require(currentTime <= proposals[_proposalId].endTime, "Too late");

        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }

    function hasVoted(address voter, uint8 _proposalId) external view returns(bool){
        return (voteRegistry[voter]&(1 << _proposalId))!=0;    
    }
    
    function getProsal(uint8 _proposalId) external view returns(
        bytes32 name,
        uint32 voteCount,//支持 42 亿次投票
        uint32 startTime,
        uint32 endTime,
        bool executed,
        bool active
    ){
        require(_proposalId<proposalCount, "Invalid proposal");
        Proposal storage proposal = proposals[_proposalId];
        return(proposal.name, proposal.voteCount, proposal.startTime, proposal.endTime, proposal.executed,(uint32(block.timestamp) >= proposal.startTime && uint32(block.timestamp) <= proposal.endTime)
        );

    }

}