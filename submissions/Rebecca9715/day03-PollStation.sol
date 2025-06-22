// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract PollStation {
    // 在这个场景中，名字数组可以不使用，只是为getCandidateNames获取候选人名称，以及在后续智能合约中方便使用这个候选人名单
    string[] public candidateNames;
    mapping(string => uint256) voteCount;

    function addCandidate(string memory _candidateNames) public{
        // 要求候选人名称不能重复
        require(!isCandidateExist(_candidateNames), "Candidate already exists");
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
    }

    // 检查候选人是否在名单的函数
    function isCandidateExist(string memory _candidateName) internal view returns (bool) {
        for (uint256 i = 0; i < candidateNames.length; i++) {
            if (keccak256(abi.encodePacked(candidateNames[i])) == keccak256(abi.encodePacked(_candidateName))) {
                return true;
            }
        }
        return false;
    }

    function vote(string memory _candidateNames) public{
        // 要求名单中的候选人才能被投票
        require(isCandidateExist(_candidateNames), "Candidate doesn't exist in array");
        voteCount[_candidateNames] += 1;
    }

    function getCandidateNames() external view returns (string[] memory) {
        return candidateNames;
    }

    function getVote(string memory _candidateNames) external view returns (uint) {
        return voteCount[_candidateNames];
    }
}
