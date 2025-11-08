//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting{

    uint8 public proposalCount; // proposalCount是干啥的？——> 提案数

    struct Proposal {   //结构体咋打来着？——> struct
        bytes32 name;
        uint32 voteCount;  //干啥用的 ——> 投票数
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }

    mapping(uint8 => Proposal) public proposals;

    mapping(address => uint256) private voterRegistry; //使用bitmap位图的选民登记册 

    mapping(uint8 => uint32) public proposalVoterCount; //跟踪每个提案的投票数

//3个事件：创建提案；投票；执行提案
    event ProposalCreated(uint8 indexed proposalId,bytes32 name);
    event Voted(address indexed voter,uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

//创建提案  Duration 投票时长
    function createProposal(bytes32 name,uint32 duration) external {
        require(duration >0,"Duration must be > 0");

        uint8 proposalId = proposalCount; 
        proposalCount++;

//memory struct  {……}:指定每个字段的值 
        Proposal memory newProposal = Proposal({
            name: name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime : uint32(block.timestamp)+duration,
            executed: false
        });
        
        proposals[proposalId] = newProposal;

        emit ProposalCreated(proposalId,name);
    }

//投票
    function vote(uint8 proposalId) external {
        // Require valid proposal
        require(proposalId < proposalCount,"Invalid proposal");

        // Check proposal voting period
        uint32 currentTime = uint32(block.timestamp);
        require(currentTime >= proposals[proposalId].startTime,"Not Start voting");
        require(currentTime <= proposals[proposalId].endTime,"Finished voting");

        // Check if already voted using bit manipulation (gas efficient)
        //掩码 按位与，检查某位置是否为1
        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << proposalId;
        require((voterData & mask) == 0,"Already voted");

        //Record vote using bitwise OR
        //按位或，把mask中第proposalId个位置设置为1，合并进voterData中，记录msg.sender对该提案投了票
        voterRegistry[msg.sender] = voterData | mask;

        // Update proposal vote count 
        proposals[proposalId].voteCount++;
        proposalVoterCount[proposalId]++;

        emit Voted(msg.sender, proposalId);
    }

//执行提案
    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        require(block.timestamp > proposals[proposalId].endTime, "Voting not ended");
        require(!proposals[proposalId].executed, "Already executed");

        proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);

        // In a real contract, execution logic would happen here 
        //例如，触发付款或DAO配置更改
    }

//Check if a certain address has voted for a proposal ???
    function hasVoted(address voter, uint8 proposalId) external view returns(bool){
        return (voterRegistry[voter] & (1 << proposalId)) != 0;
    }

    function getProposal(uint8 proposalId) external view returns(
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool executed,
        bool active
    ){
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
