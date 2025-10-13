//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{

    // 存储所有候选人名字的数组
    string[] public candidateNames;
    // 映射：候选人名字 => 得票数
    mapping(string => uint256) voteCount;
    // 添加候选人函数
    function addCandidates(string memory _candidateNames) public {
        // 将候选人添加到数组
        candidateNames.push(_candidateNames);  
        // 初始化该候选人的票数为0 
        voteCount[_candidateNames] = 0;
    }
    
     // 投票函数
    function vote(string memory _condidateNames) public{
        // 给指定候选人增加一票
        voteCount[_condidateNames]++;
    }

 // 获取所有候选人名字
function getCandidateNames() public view returns(string[] memory){
    return candidateNames;
}

// 获取指定候选人的得票数
function getVote(string memory _candidateNames) public view returns(uint256){
    return voteCount[_candidateNames];
}
}