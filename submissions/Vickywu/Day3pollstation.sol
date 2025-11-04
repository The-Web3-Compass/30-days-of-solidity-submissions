// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    Candidate[] public candidates;
    mapping(string => bool) private candidateExists;  // 记录候选人是否存在
    mapping(address => bool) private hasVoted;

    function addCandidate(string memory _candidateName) public {
        require(!candidateExists[_candidateName], "Candidate already exists");
        candidates.push(Candidate(_candidateName, 0));
        candidateExists[_candidateName] = true;
    }

    function vote(string memory _candidateName) public {
        require(!hasVoted[msg.sender], "Already voted");
        require(candidateExists[_candidateName], "Invalid candidate");
        for (uint256 i = 0; i < candidates.length; i++) {
            if (keccak256(bytes(candidates[i].name)) == keccak256(bytes(_candidateName))) {
                candidates[i].voteCount += 1;
                break;
            }
        }
        hasVoted[msg.sender] = true;
    }

    function getVoteCount(string memory _candidateName) public view returns (uint256) {
        require(candidateExists[_candidateName], "Invalid candidate");
        for (uint256 i = 0; i < candidates.length; i++) {
            if (keccak256(bytes(candidates[i].name)) == keccak256(bytes(_candidateName))) {
                return candidates[i].voteCount;
            }
        }
        return 0;
    }
}