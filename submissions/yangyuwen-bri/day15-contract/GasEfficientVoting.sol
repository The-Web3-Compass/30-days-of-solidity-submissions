//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

contract GasEfficientVoting{
    uint8 public proposalCount; //核心：用于提案的编号记录

    struct Proposal{
        bytes32 name;
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }
    /**
    * 1.give every proposal a proposalID
    * 2.give everyone a <<bitmap>> and use "01" to mark if she vote or not
    * 3.count the votes of every proposal
    * 二进制位的编号方式:从右至左，例如编号0-2 投了2号 则记录 100
    */
    mapping(uint8 => Proposal) public proposals; // 用0～255来标识proposal
    mapping(address => uint256) private userVoted; // 投票记录：每个人对应一组针对每个proposal的投票记录(0/1)
    mapping(uint8 => uint32) public voterCount;// 投票得数

    /**
    * 创建事件记录：proposal created、someone voted、vote closed
    */
    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed user, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    /**
    * 主要程序：1.创建并记录proposal 2.投票 
    */
    function createProposal(bytes32 name, uint32 duration) external {
        require(duration > 0, "duration must be greater than zero.");

        uint8 proposalId = proposalCount;
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
        
        require(proposalId < proposalCount, "invalid proposal id");

        uint32 currentTime = uint32(block.timestamp);
        require(proposals[proposalId].startTime <= currentTime, "voting time is not started yet.");
        require(currentTime <= proposals[proposalId].endTime, "voting is not ended yet.");

        // 核心：位运算
        uint256 voteData = userVoted[msg.sender];
        uint256 mask = 1 << proposalId; //把1左移到当前proposal定位，1的二进制类似：0001
        require((mask & voteData) == 0, "already voted");

        userVoted[msg.sender] = voteData | mask; //| 或按位的规则是：只要有一位是1，结果就是1

        proposals[proposalId].voteCount ++;
        voterCount[proposalId] ++;

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
        return(userVoted[voter] & 1 << proposalId != 0);
    }

    function getProposal(uint8 proposalId) external view returns(
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool executed
    ){
        require(proposalId < proposalCount, "invalid proposal id");

        Proposal storage proposal = proposals[proposalId];

        return(
            proposal.name,
            proposal.voteCount,
            proposal.startTime,
            proposal.endTime,
            proposal.executed
        );

    }

}