// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract pollStation{

    string[] public candidateNames; // 数组-存储候选人列表
    mapping (string => uint256) public voteCount;// 映射-候选人投票数;voteCount 设为 public，允许免费查询得票数（无需额外 getVote 函数，但保留以兼容原逻辑）。
    mapping (address => bool) private hasVoted;// 记录投票者地址

    //添加候选人
    function addCandidateNames(string memory _candidateNames) public {
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;  // 初始化票数为0

    }
    

    //获取候选人列表
    function getCandidateNames() public view returns(string[] memory){
        return(candidateNames);
    } 

    //为候选人投票（每个地址只能投票一次）
    function vote(string memory _candidateNames) public{
        require(!hasVoted[msg.sender], "You have already voted!"); // 防止重复投票
        voteCount[_candidateNames]++; 
        hasVoted[msg.sender] = true; // 标记地址为已投票
    }
    
}