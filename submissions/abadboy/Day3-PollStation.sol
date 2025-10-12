// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract PollStation {
    string[] public candidateNames; // some candidate name
    mapping(string => uint256) public voteCount; // 候选人得票数映射
    mapping(address => bool) public hasVoted;

    // 添加候选人
    function addCandidateNames(string memory _candidateNames) public {
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
    }

    // 辅助函数：检查候选人是否已存在
    function isCandidate(string memory _candidateName) private view returns (bool){
        for(uint256 i = 0; i < candidateNames.length; i++) {
            if (keccak256(abi.encodePacked(candidateNames[i])) == keccak256(abi.encodePacked(_candidateName))) {
                return true;
            }
        }
        return false;
    }

    // 投票
    function vote(string memory _candidateName) public {
        // 验证候选人是否存在
        require(isCandidate(_candidateName), "Invalid candidate name");
        // 防止重复投票
        require(!hasVoted[msg.sender], "You have already voted");
        voteCount[_candidateName] += 1;
        hasVoted[msg.sender] = true;
    }

    // 查看候选人列表
    function getCandidateNames() public view returns (string[] memory){
        return candidateNames;
    }

    // 查看候选人得票数
    function getVote(string memory _candidateNames) public view returns(uint256) {
        require(isCandidate(_candidateNames), "Invalid candidate name");
        return voteCount[_candidateNames];
    }

}