// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{
    string[] public personNames;
    mapping(string => uint256) voteCount;

    // 初始化一个新的候选人，加入数组，并且map映射初始票数为0
    function addCandidateNames(string memory _personNames) public {
        personNames.push(_personNames);
        voteCount[_personNames] = 0;
    }

    // 获取候选人名单列表
    function getcandidateNames() public view returns (string[] memory){
        return personNames;
    }

    // 给指定候选人投一票
    function vote(string memory _personNames) public{
        voteCount[_personNames] += 1;
    }

    // 返回候选人当前票数
    function getVote(string memory _personNames) public view returns (uint256){
        return voteCount[_personNames];
    }
}