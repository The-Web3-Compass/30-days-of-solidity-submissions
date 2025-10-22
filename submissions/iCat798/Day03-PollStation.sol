// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract pollStation{

    string[] public candidateNames; //数组-存储列表
    mapping (string => uint256) voteCount;//映射-存储投票计数

    function addCandidateNames(string memory _candidateNames) public {
        candidateNames.push(_candidateNames);//添加候选人
        voteCount[_candidateNames] = 0;
    }

    function getCandidateNames() public view returns(string[] memory){
        return(candidateNames);//检查候选人列表
    } 

    function vote(string memory _candidateNames) public{
        voteCount[_candidateNames] +=1; //为候选人投票
    }

    function getVote(string memory _candidateNames) public view returns (uint256){
        return voteCount[_candidateNames];
    }

}