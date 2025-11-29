// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation{
    // 定义 候选人集合，候选人票数映射
    string[] public candidateNames;
    mapping (string => uint256) voteCount;
    mapping (address => bool) hasVoted;

    // 添加候选人
    function addCandidate(string memory _candidateNames) public{
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
    }

    // 为候选人投票
    function vote(string memory _candidateNames) public{
        //防止多次投票 – 添加 mapping(address => bool) 来跟踪用户是否已经投票。
        require(!hasVoted[msg.sender], "You have already voted.");
        hasVoted[msg.sender] = true;
        voteCount[_candidateNames] += 1;
    }
    
    // 检查候选人列表
    function getcandidateNames() public view returns (string[] memory){
        return candidateNames;
    }

    // 检查候选人票数
    function getVote(string memory _candidateNames) public view returns (uint256){
        return voteCount[_candidateNames];
    }


}