// SPDX-License-Identifer: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting{
    //使用uint8代替uint256  uint8 取值范围 0 ~ 2^8-1=255
    uint8 public proposalCount;  //我们可能不会有超过255个proposal

    //proposal结构体
    struct Proposal{
        bytes32 name; //固定大小，比字符串便宜
        uint32 voteCount; //足够42亿张选票
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }

    mapping(uint8 => Proposal) public proposals; //用mapping来去存储对应的proposal  数字对应结构体

    mapping(address => uint256) private voterRegistry; 

    mapping(uint8 => uint32) public proposalVoterCount;

    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    function createProposal(bytes32 name, uint32 duration) external {
        require(duration > 0, "Duration must be > 0");

        uint8 proposalId = proposalCount;  //为这个proposal生成唯一的ID
        proposalCount++;

        Proposal memory newProposal = Proposal({
            name: name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + duration,
            executed: false
        });

        proposals[proposalId] = newProposal;
        
        emit ProposalCreated(proposalId, name);
    }

    function vote(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");

        uint32 currentTime = uint32(block.timestamp);
        require(currentTime >= proposals[proposalId].startTime, "Voting not started");
        require(currentTime >= proposals[proposalId].endTime, "Voting ended");

        uint256 voterData = voterRegistry[msg.sender];  //voterData最初始的应该是全0
        uint256 mask = 1 << proposalId;
        require((voterData & mask) == 0, "Already voted");  //判断是否投票

        voterRegistry[msg.sender] = voterData | mask;  //记录投票信息

        proposals[proposalId].voteCount++;  //该候选人的票数加1
        proposalVoterCount[proposalId]++;  //这一句不理解

        emit Voted(msg.sender, proposalId);
    }

    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        require(block.timestamp > proposals[proposalId].endTime, "Voting not ended");
        require(!proposals[proposalId].executed, "Already executed");

        proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);
    }

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

        return(
            proposal.name,
            proposal.voteCount,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            (block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime)
        );
    }



}
