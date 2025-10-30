// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation{
    string[] public candidateNames;
    mapping (string => uint256) voteCount;
    //在编写函数之前，我们需要高效地存储候选人及其票数

    function addCandidateNames(string memory _candidateNames) public {
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
    }
    // 我们需要一个函数来添加候选人名字到candidateNames数组中，并初始化voteCount映射
    
    function getcandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }
    // 检索候选人列表

    function vote(string memory _candidateNames) public {
        voteCount[_candidateNames] += 1;
    }
    //为候选人投票

    function getVote(string memory _candidateNames) public view returns (uint256){
        return voteCount[_candidateNames];
    }
    //检索候选人票数

}