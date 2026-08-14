// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    string[] public candidateNames;
    mapping(string => uint256) public voteCount;
    mapping(address => bool) public hasVoted;
    mapping(string => bool) public isCandidate;
    uint256 public votingStart;
    uint256 public votingEnd;
    address public admin;

    constructor(uint256 _durationInDays) {
        admin = msg.sender;
        votingStart = block.timestamp;
        votingEnd = block.timestamp + (_durationInDays * 1 days);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    function addCandidateName(string memory _candidateNames) public onlyAdmin {
        require(!isCandidate[_candidateNames], "already a candidate");
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
        isCandidate[_candidateNames] = true;
    }

    function getCandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }

    function vote(string memory _candidateNames) public {
        require(!hasVoted[msg.sender], "Already voted");
        require(isCandidate[_candidateNames], "Invalid candidate");
        require(block.timestamp <= votingEnd, "Voting ended");
        hasVoted[msg.sender] = true;
        voteCount[_candidateNames] += 1;
    }

    function getVote(string memory _candidateNames) public view returns (uint256) {
        return voteCount[_candidateNames];
    }

    function getWinner() public view returns (string memory winner, uint256 winningVoteCount) {
        require(block.timestamp > votingEnd, "Voting still active");

        uint256 arrayLength = candidateNames.length;
        winningVoteCount = 0;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (voteCount[candidateNames[i]] > winningVoteCount) {
                winner = candidateNames[i];
                winningVoteCount = voteCount[candidateNames[i]];
            }
        }
    }
}
