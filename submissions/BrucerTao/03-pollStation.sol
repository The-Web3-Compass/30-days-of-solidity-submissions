//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract PollStatison {
    string[] public candidateNames;
    mapping(string => uint256) voteCount;
    mapping(address => bool) public hasVoted; // 跟踪用户是否已投票

    //add candidateNames
    function addCandidateNames(string memory _candidateNames) public {
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
    }

    //get candidateNames
    function getCandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }

    //vote add candidate
    function vote(string memory _candidateNames) public {
        // 检查用户是否已经投票
        require(!hasVoted[msg.sender], "You have already voted");
        
        // 检查候选人是否存在
        bool candidateExists = false;
        for (uint i = 0; i < candidateNames.length; i++) {
            if (keccak256(bytes(candidateNames[i])) == keccak256(bytes(_candidateNames))) {
                candidateExists = true;
                break;
            }
        }
        require(candidateExists, "Candidate does not exist");
        
        // 记录投票并标记用户已投票
        voteCount[_candidateNames] += 1;
        hasVoted[msg.sender] = true;
    }

    // get candidate vote
    function getVote(string memory _candidateNames) public view returns (uint256) {
        return voteCount[_candidateNames];
    }
}