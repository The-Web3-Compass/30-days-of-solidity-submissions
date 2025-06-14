// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {

struct Candidate {
string name; 
uint voteCount; 
}

Candidate[] private _candidates;

mapping(address => uint) private _voterChoice;

event Voted(uint indexed candidateId, address indexed voter, uint timestamp);

event CandidateAdded(uint indexed candidateId, string name, uint timestamp);

function addCandidate(string memory _name) public {
uint candidateId = _candidates.length + 1;
_candidates.push(Candidate(_name, 0));
emit CandidateAdded(candidateId, _name, block.timestamp);
}

function vote(uint _candidateId) public {
require(_voterChoice[msg.sender] == 0, "Error: You have already voted."); 
require(_candidateId > 0 && _candidateId <= _candidates.length, "Error: Invalid candidate ID."); 

_candidates[_candidateId - 1].voteCount++; 
_voterChoice[msg.sender] = _candidateId;  
emit Voted(_candidateId, msg.sender, block.timestamp);
}

function getAllCandidates() public view returns (Candidate[] memory) {
return _candidates;
}

function getVotesForCandidate(uint _candidateId) public view returns (uint) {
require(_candidateId > 0 && _candidateId <= _candidates.length, "Error: Invalid candidate ID.");
return _candidates[_candidateId - 1].voteCount;
}

function getCandidateDetails(uint _candidateId) public view returns (string memory name, uint voteCount) {
require(_candidateId > 0 && _candidateId <= _candidates.length, "Error: Invalid candidate ID.");
Candidate storage candidate = _candidates[_candidateId - 1];
return (candidate.name, candidate.voteCount);
}

function getAllVoteCounts() public view returns (uint[] memory) {
uint[] memory counts = new uint[](_candidates.length);
for (uint i = 0; i < _candidates.length; i++) {
counts[i] = _candidates[i].voteCount;
}
return counts;
}

function getVoterChoice(address _voterAddress) public view returns (uint) {
return _voterChoice[_voterAddress];
}
}