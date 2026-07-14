// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PollingStation {

    string[]  candidateNames;
    mapping(string => uint256)  voteCount;
    mapping(address => bool)  hasVoted;
    mapping(string => bool)  isCandidate;

    uint256  votingStart;
    uint256  votingEnd;

    address  admin;

    constructor() {
        admin = msg.sender;
        votingStart = block.timestamp;
        votingEnd = block.timestamp + 10 minutes;
    }

    event Voted(string candidateName, address indexed voter, uint256 timestamp);

    modifier onlyAdmin {
        require(msg.sender == admin, "Not Admin");
        _;
    }

    function addCandidate(string memory name) external onlyAdmin {
        require(!isCandidate[name], "Candidate already exists");

        candidateNames.push(name);
        voteCount[name] = 0;
        isCandidate[name] = true;
    }

    function vote(string memory candidate) external {
        require(block.timestamp >= votingStart, "Voting not started");
        require(block.timestamp <= votingEnd, "Voting ended");
        require(!hasVoted[msg.sender], "Already voted");
        require(isCandidate[candidate], "Not a candidate");

        hasVoted[msg.sender] = true;
        voteCount[candidate]++;

        emit Voted(candidate, msg.sender, block.timestamp);
    }

    function getVote(string memory candidate) external view returns (uint256) {
        return voteCount[candidate];
    }

    function getCandidateList() external view returns (string[] memory) {
        return candidateNames;
    }

    function getWinner() external view returns (string memory winner, uint256 winningVotes) {
        require(block.timestamp > votingEnd, "Voting is still in progress");

        for (uint256 i = 0; i < candidateNames.length; i++) {
            uint256 votes = voteCount[candidateNames[i]];

            if (votes > winningVotes) {
                winningVotes = votes;
                winner = candidateNames[i];
            }
        }
    }
}