//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GasEfficientVoting {
    uint8 public proposalCount;     //存储当前提案总数，每创建一个提案就自增 1

    //定义提案的数据结构
    struct Proposal {
        bytes32 name;     //提案名称，使用 bytes32 节省 gas
        uint32 voteCount;     //当前票数，uint32 足够表示大多数应用
        uint32 startTime;     //投票起时间，uint32 表示 Unix 时间戳
        uint32 endTime;     //投票止时间，uint32 表示 Unix 时间戳
        bool executed;     //布尔值，标记提案是否已被执行
    }

    //将 proposalId 映射到 Proposal 对象，方便快速查找
    mapping(uint8 => Proposal) public proposals;     

    //存储每个地址的投票记录，使用位掩码（bitmask）记录是否已对每个提案投票
    mapping(address=> uint256) private voterRegistry;

    //记录每个提案的总投票人数，方便前端快速获取参与人数
    mapping(uint8 => uint32) public proposalVoterCount;

    event ProposalCreated(uint8 indexed proposalId, bytes32 name);     //当新提案被创建时触发
    event Voted(address indexed voter, uint8 indexed proposalId);     //当用户对某个提案投票时触发
    event ProposalExecuted(uint8 indexed proposalId);     //当投票结束并执行提案时触发

    //创建一个新提案，并存储在区块链上
    function createProposal(bytes32 name, uint32 duration) external {    
        require(duration > 0, "Duration must be > 0");     //检查投票持续时间必须大于 0，否则交易回滚

        uint8 proposalId = proposalCount;     //给新提案分配唯一 ID：等于当前提案数量
        proposalCount++;     //提案计数器自增，为下一条提案准备

        //在内存中创建一个 Proposal 对象（内存对象创建后再写入存储，减少 gas）
        Proposal memory newProposal = Proposal({
            name: name,     //提案名称
            voteCount: 0,     //初始票数 0
            startTime:uint32(block.timestamp),     //投票开始时间 = 当前区块时间
            endTime: uint32(block.timestamp) + duration,     //投票结束时间 = 当前时间 + duration
            executed: false     //初始为 false
        }); 

        //将内存中的 Proposal 对象写入存储映射 proposals，永久存储在区块链上
        proposals[proposalId] = newProposal; 

        //触发事件，记录提案创建信息，前端可以监听并更新 UI
        emit ProposalCreated(proposalId, name);
    }

    //给指定提案投票，检查投票是否在有效时间内，并确保用户未重复投票；调用后触发 Voted 事件
    function vote(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");     //确认提案存在，否则交易回滚

        //检查投票时间有效性
        uint32 currentTime = uint32(block.timestamp);
        require(currentTime >= proposals[proposalId].startTime, "Voting not started");     //当前时间 >= 投票开始时间
        require(currentTime <= proposals[proposalId].endTime, "Voting ended");     //当前时间 <= 投票结束时间
        
        //使用位掩码检查用户是否已投票
        uint256 voteData = voterRegistry[msg.sender];     //voteData；用户投票记录（bitmask）
        uint256 mask = 1 << proposalId;     //mask：对应提案 ID 的位
        require((voteData & mask) == 0, "Already voted");     //检查 bit 是否为 0，0 = 未投票，1 = 已投票

        //将用户对该提案的投票状态写入位掩码，标记已投票
        voterRegistry[msg.sender] = voteData | mask;

        proposals[proposalId].voteCount++;     //提案票数增加 1
        proposalVoterCount[proposalId]++;     //总投票人数增加 1

        emit Voted(msg.sender, proposalId);     //触发事件，记录投票操作，前端可监听显示投票进度
    }

    //在投票结束后执行提案，标记提案已执行
    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");      //检查提案存在
        require(block.timestamp > proposals[proposalId].endTime, "Voting not ended");     //检查投票已结束
        require(!proposals[proposalId].executed, "Already executed");     //检查提案尚未执行
        
        proposals[proposalId].executed = true;     //标记提案已执行，防止重复执行
        emit ProposalExecuted(proposalId);     //触发事件记录执行操作，前端可更新状态显示“已执行”
    }

    //查询指定提案详细信息
    function getProposal(uint8 proposalId) external view returns (
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool executed,
        bool active     //当前是否在投票期
    ) {

        //确保提案存在
        require(proposalId < proposalCount, "Invalid proposal");
        
        //获取存储中的 Proposal 对象引用
        Proposal storage proposal = proposals[proposalId];
        
        //返回提案信息
        return (
            proposal.name,
            proposal.voteCount,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,

            //返回当前提案是否处于活跃投票期（active）(即时计算活跃状态，无需额外存储，节省 gas)
            (block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime)
        );
    }

}