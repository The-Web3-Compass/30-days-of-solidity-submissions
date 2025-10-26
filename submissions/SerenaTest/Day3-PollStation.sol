//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract PollStation{
    //声明数组
    string[] public candidate;
    // mapping(string => uint256) public voteCount;
    //数组的映射
    mapping(string => uint256) voteCount;

//添加候选人列表并将每位候选人的选票初始化为0
    function addCandidate(string memory _candidate) public {
        candidate.push(_candidate);
        voteCount[_candidate] = 0;
    }

//为指定候选人投票 该候选人对应选票加一
    function voteForCandidate(string memory _candidate) public{
        voteCount[_candidate]++;
    }

//显示候选人列表
    function getCandidate() public view returns(string[] memory){
        return candidate;
    }
//显示某位候选人选票
    function getVote(string memory _candidate) public view returns(uint256){
        return voteCount[_candidate];
    }

    //返回所有候选人选票  voteCount作为映射无法直接作为uint256返回  需要再使用一个数组承接所有的选票数
    function getAllVotes() public view returns(string[] memory,uint256[] memory){
        uint256[] memory allVotes = new uint256[](candidate.length);
        for(uint256 i = 0;i < candidate.length;i ++){
            allVotes[i] = voteCount[candidate[i]];
        }
        return (candidate,allVotes);
    }

}