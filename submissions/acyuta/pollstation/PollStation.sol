// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PollStation {
    event VoteSent(uint256 indexed candidateId);

    error PollStation__AlreadyVoted();
    error PollStation__InvalidCandidateId();
    error PollStation__NoVotesRecorded();

    string[] public candidates;
    mapping(uint256 => uint256) public voteCount;
    mapping(address => bool) private hasVoted;

    uint256 private winnerIndex;
    uint256 private maxVotes;

    constructor(string[] memory _candidates) {
        candidates = _candidates;
    }

    function voteForCandidates(uint256 _candidateId) public {
        if (hasVoted[msg.sender]) {
            revert PollStation__AlreadyVoted();
        }

        if (candidates.length <= _candidateId) {
            revert PollStation__InvalidCandidateId();
        }

        emit VoteSent(_candidateId);

        voteCount[_candidateId] += 1;
        hasVoted[msg.sender] = true;

        if (voteCount[_candidateId] > maxVotes) {
            maxVotes = voteCount[_candidateId];
            winnerIndex = _candidateId;
        }
    }

    function getCandidateNames() public view returns (string[] memory) {
        return candidates;
    }

    function getVotes(uint256 _candidateId) public view returns (uint256) {
        if (_candidateId >= candidates.length) {
            revert PollStation__InvalidCandidateId();
        }

        return voteCount[_candidateId];
    }

    function getWinner() public view returns (string memory) {
        if (maxVotes == 0) {
            revert PollStation__NoVotesRecorded();
        }
        return candidates[winnerIndex];
    }
}
