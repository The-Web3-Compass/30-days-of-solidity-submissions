// SPDX license MIT
pragma solidity ^0.8.0;

contract PollStation { 
	uint256[] public votes;
	mapping (address => uint) public hasVoted;

	constructor(uint numCandidates) {
		votes = new uint [](numCandidates);
}

function vote(uint candidateIndex) public {
	require(hasVoted[msg.sender] == 0, "you already voted");
	require(candidateIndex < votes.length, "inexistant candidate");

	votes[candidateIndex] += 1;
	hasVoted[msg.sender] = candidateIndex + 1;
	}

function getVotes(uint candidateIndex) public view returns (uint) {
        require(candidateIndex < votes.length, "inexistant candidate");
        return votes[candidateIndex];
    }

}
