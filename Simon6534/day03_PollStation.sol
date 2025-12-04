// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract PollStation{
    string[] public candidateNames;
    mapping(string => uint256) public voteCount;
    
    function addCandidates(string memory _candidateName) public {
        candidateNames.push(_candidateName);
        voteCount[_candidateName] = 0;
    }

    function vote(string memory _candidateName) public {
        voteCount[_candidateName]++;
    }
    // 查看候选人列表
    function getCandidateName() public view returns (string[] memory) {
        return candidateNames;
    }
    // 查看投票数量
    function getVotes(string memory _candidateName) public view returns  (uint256){
        return voteCount[_candidateName];
    }

}