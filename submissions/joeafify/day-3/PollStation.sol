// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract PollStation {
    address public owner;
    uint public candidateCount;
    uint[] public votes;
    mapping(address => uint) public voterChoice;
    mapping(address => bool) public hasVoted;

    event CandidateAdded(uint candidateIndex);
    event Voted(address indexed voter, uint candidateIndex);

    constructor(uint _candidateCount) {
        require(_candidateCount > 0, "Must have at least one candidate");
        owner = msg.sender;
        candidateCount = _candidateCount;
        votes = new uint[](_candidateCount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    function vote(uint _candidateIndex) public {
        require(!hasVoted[msg.sender], "Already voted");
        require(_candidateIndex < candidateCount, "Invalid candidate");

        hasVoted[msg.sender] = true;
        voterChoice[msg.sender] = _candidateIndex;
        votes[_candidateIndex]++;

        emit Voted(msg.sender, _candidateIndex);
    }

    function getVotes(uint _candidateIndex) public view returns (uint) {
        require(_candidateIndex < candidateCount, "Invalid candidate");
        return votes[_candidateIndex];
    }

    function getAllVotes() public view returns (uint[] memory) {
        return votes;
    }

    function addCandidate() public onlyOwner {
        votes.push(0);
        candidateCount++;
        emit CandidateAdded(candidateCount - 1);
    }
}
