// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract GasEfficientVoting {
    
    uint8 public proposalCount;
    
    struct Proposal {
        bytes32 name;
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }
    
    mapping(uint8 => Proposal) public proposals;
    mapping(address => uint256) private voterRegistry;
    
    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);
  
    function createProposal(bytes32 name, uint32 duration) external {
        require(duration > 0, "Duration must be > 0");
        
        uint8 proposalId = proposalCount;
        proposalCount++;
        
        proposals[proposalId] = Proposal({
            name: name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + duration,
            executed: false
        });
        
        emit ProposalCreated(proposalId, name);
    }
    
    /**
     * @dev 对一个提案进行投票。
     * @param proposalId 提案ID。
     */
    function vote(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        
        Proposal storage proposal = proposals[proposalId];
        
        uint32 currentTime = uint32(block.timestamp);
        require(currentTime >= proposal.startTime, "Voting not started");
        require(currentTime <= proposal.endTime, "Voting ended");
        
        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << proposalId;
        require((voterData & mask) == 0, "Already voted");
        
        voterRegistry[msg.sender] = voterData | mask;
        
        proposal.voteCount++;
        
        emit Voted(msg.sender, proposalId);
    }
    
    /**
     * @dev 在投票结束后执行一个提案。
     * @param proposalId 提案ID。
     */
    function executeProposal(uint8 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Already executed");
        
        proposal.executed = true;
        
        emit ProposalExecuted(proposalId);
    }
    
    /**
     * @dev 检查一个地址是否已对某个提案投票。
     * @param voter 投票人地址。
     * @param proposalId 提案ID。
     * @return 如果已投票则返回true。
     */
    function hasVoted(address voter, uint8 proposalId) external view returns (bool) {
        return (voterRegistry[voter] & (1 << proposalId)) != 0;
    }
    
    /**
     * @dev 获取一个提案的详细信息。
     */
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
