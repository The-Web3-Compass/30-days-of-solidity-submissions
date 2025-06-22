//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// 一个能够优化gas消耗的投票
contract GasEfficientVoting{
    // uint8比uint256便宜31 extra bytes，按照二进制
    uint8 public proposalCount;
    struct Proposal{
        // 原先是string，更贵一些
        bytes32 name;
        // 需要足够的range，但成本也要低
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }

    // array比map更贵，多层map比单层map贵
    // O(1)，array更高，数据结构
    mapping(uint8 => Proposal) public proposals;
    // 注册系统：uint256代表不同的提议？？
    mapping(address => uint256)private voterRegistry;
    // 每个提议有多少人选择
    mapping(uint8 =>uint32)public proposalVoterCount;

    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    // 创建一个新的提案，设置名称和投票持续时间
    function createProposal(bytes32 _name, uint32 duration) external{
        // 持续时间必须大于0
        require(duration > 0, "Durations should be more than 0");
        uint8 proposalId = proposalCount;
        // 提案数量递增即可
        proposalCount++;
        Proposal memory newProposal = Proposal({
            name: _name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + duration,
            executed: false
        });
        // 存入提案的map
        proposals[proposalId] = newProposal;
        emit ProposalCreated(proposalId, _name);
    }

    // 投票
    function vote(uint8 proposalId) external{
        // 提案数量ID是逐渐递增的，因此id小于count的时候则不存在
        require(proposalId < proposalCount, "Invalid Proposal");
        uint32 currentTime = uint32(block.timestamp);
        // 判断是否在有效时间内
        require(currentTime >= proposals[proposalId].startTime, "Voting has not started");
        require(currentTime <= proposals[proposalId].endTime, "Voting has ended");

        // 位运算技巧：检查这个地址是否已经投过票
        // 使用 uint256 存储多个投票状态，比 mapping(address => mapping(uint => bool)) 省很多 gas。
        uint256 voterData = voterRegistry[msg.sender];
        // 设置对应 bit：`<<` 是左移位运算符。它是一种位运算操作符，用于将二进制数的所有位向左移动指定的位数
        // 表示将1的二进制位数向左移动proposalId位，如proposalId=2，则mask=000100
        uint256 mask = 1 << proposalId;
        // 判断是否投过票
        require((voterRegistry[msg.sender] & mask) == 0, "Already voted");

        // 标记我投过票了
        voterRegistry[msg.sender] = voterData | mask;
        proposals[proposalId].voteCount++;
        proposalVoterCount[proposalId]++;

        emit Voted(msg.sender, proposalId);

    }
    //  执行提案
    function executeProposal(uint8 proposalId) external{
        require(proposalId < proposalCount, "Invalid Proposal");
        require(block.timestamp > proposals[proposalId].endTime, "Voting not ended ");
        require(!proposals[proposalId].executed, "Already executed");
        proposals[proposalId].executed = true;
        emit ProposalExecuted(proposalId);
    }

    function hasVoted(address voter, uint8 proposalId)external view returns(bool){
        return(voterRegistry[voter] & (1 << proposalId) != 0);
    }

      
    function getProposal(uint8 proposalId) external view returns (
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool executed,
        bool active
        ) 
{
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