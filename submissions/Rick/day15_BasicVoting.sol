// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BasicVoting {

    struct Proposal {
        // 投票活动名称
        string name;
        // 投票次数
        uint voteCount;
        // 开始时间
        uint startTime;
        // 结束时间
        uint endTime;
        // 投票活动是否已经关闭
        bool executed;
    }

    // 投票活动列表
    Proposal[] public ProposalArray ;
    // 用户投票记录  用户A给活动1投票false
    mapping(address => mapping (uint =>bool)) public hasVoted;

    // 创建投票活动
    function createProposal(string memory name , uint duration) public {
        Proposal memory pro = Proposal({
            name: name,
            voteCount: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            executed: false
        });
        ProposalArray.push(pro);
    }

    // 投票
    function vote(uint proposalId) public {
        Proposal storage pro = ProposalArray[proposalId];

        require(block.timestamp >= pro.startTime, "must > startTime");
        require(block.timestamp <= pro.startTime, "must < endTime");
        require(!hasVoted[msg.sender][proposalId] , "already vote");

        pro.voteCount ++;
        hasVoted[msg.sender][proposalId] = true;
    }

    // 关闭活动
    function executeProposal(uint proposalId) public {
        Proposal storage pro = ProposalArray[proposalId];
        require(block.timestamp > pro.endTime, "Too early");
        require(!pro.executed, "Already executed");


        pro.executed = true;
    }


}