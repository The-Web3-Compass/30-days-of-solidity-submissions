// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * @title 投票站合约 PollStation
 * @notice 此合约用于添加候选人、进行投票并统计得票数
 * @dev 本合约使用 unit[] 数组和 mapping 来实现基本的投票功能
 */

// 💡 想象这个场景：
// 创建一个完全透明、无法篡改的数字投票站，每个钱包地址一票，永久记录在区块链上！这就是我们要实现的民主协议 ✨

// 🛠 你将亲手构建：
// - 创建候选人数组 uint[] candidates
// - 建立投票记录 mapping(address => uint) votes
// - 实现 vote(uint candidateId) 投票函数
// - 添加 getResults() 查看投票结果
// - 内置防重复投票机制

contract PollStation {
    // 候选人数组，存储候选人ID
    uint[] public candidates;
    
    // 投票记录：地址 => 候选人ID
    mapping(address => uint) public votes;
    
    // 候选人得票数统计：候选人ID => 得票数
    mapping(uint => uint) public candidateVotes;
    
    // 记录已投票的地址
    mapping(address => bool) public hasVoted;
    
    // 事件：当有人投票时触发
    event VoteCast(address indexed voter, uint indexed candidateId);
    
    // 事件：当添加候选人时触发
    event CandidateAdded(uint indexed candidateId, string name);
    
    // 添加候选人
    function addCandidate(string memory name) public {
        candidates.push(candidates.length);
        emit CandidateAdded(candidates.length - 1, name);
    }
    
    // 投票函数
    function vote(uint candidateId) public {
        // 检查候选人ID是否有效
        require(candidateId < candidates.length, "Invalid candidate ID");
        
        // 检查是否已经投过票
        require(!hasVoted[msg.sender], "You have already voted");
        
        // 记录投票
        votes[msg.sender] = candidateId;
        hasVoted[msg.sender] = true;
        
        // 增加候选人得票数
        candidateVotes[candidateId]++;
        
        // 触发投票事件
        emit VoteCast(msg.sender, candidateId);
    }
    
    // 获取投票结果
    function getResults() public view returns (uint[] memory) {
        return candidates;
    }
    
    // 获取候选人得票数
    function getCandidateVotes(uint candidateId) public view returns (uint) {
        require(candidateId < candidates.length, "Invalid candidate ID");
        return candidateVotes[candidateId];
    }
    
    // 获取所有候选人的得票数
    function getAllVotes() public view returns (uint[] memory) {
        uint[] memory voteCounts = new uint[](candidates.length);
        for (uint i = 0; i < candidates.length; i++) {
            voteCounts[i] = candidateVotes[i];
        }
        return voteCounts;
    }
    
    // 获取候选人总数
    function getCandidateCount() public view returns (uint) {
        return candidates.length;
    }
    
    // 检查地址是否已投票
    function checkVoted(address voter) public view returns (bool) {
      return hasVoted[voter];
    }
}
