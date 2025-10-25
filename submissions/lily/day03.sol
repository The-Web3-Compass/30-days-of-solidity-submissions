// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;   

contract PollStation {
    string[] public candidateNames;
    mapping(string => uint256) voteCount;  // 候选人 => 选票数
    mapping(string => bool) isCandidate;
    // address[] public users;
    // mapping(address => bool) ifvote;

    function addCandidateNames(string memory _name) public {  // 写了public才能在合约外调用
        candidateNames.push(_name);
        voteCount[_name] = 0;
        isCandidate[_name] = true;
    }

    function getCandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }
    // 自动生成的candidateNames(idx)是通过下标访问对应元素


    function vote(string memory _name) public returns (bool) {
        if (isCandidate[_name]) {  // mapping 没有get函数
            voteCount[_name]++;
            return true;
        }
        return false;
    }

    function getVote(string memory _name) public view returns (uint256) {
        return voteCount[_name];  // _name不在voteCount中时默认返回0
    }
}