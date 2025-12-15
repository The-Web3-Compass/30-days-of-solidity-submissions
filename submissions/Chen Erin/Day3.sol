// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    string[] public candidateNames;
    mapping(string => uint256) private voteCount;
    mapping(address => bool) public hasVoted;
    mapping(string => bool) private isCandidate; // 用来检查候选人是否存在

    // 添加候选人
    function addCandidateNames(string memory _candidateNames) public {
        require(!isCandidate[_candidateNames], "Candidate already exists");
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
        isCandidate[_candidateNames] = true;
    }

    // 获取候选人列表
    function getCandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }

    // 投票
    function vote(string memory _candidateNames) public {
        require(!hasVoted[msg.sender], "You have already voted");
        require(isCandidate[_candidateNames], "Candidate does not exist");

        voteCount[_candidateNames] += 1;
        hasVoted[msg.sender] = true;
    }

    // 查询候选人得票
    function getVote(string memory _candidateNames) public view returns (uint256) {
        require(isCandidate[_candidateNames], "Candidate does not exist");
        return voteCount[_candidateNames];
    }
}