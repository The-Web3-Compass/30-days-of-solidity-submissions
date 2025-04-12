// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    
  uint256[] candidateIds = [101, 102, 103 , 104, 105];

  struct  CandidateVotesDetailsType {
    address[] voterAddresses;
    uint256 totalVote;
  }
 
  // candidateIds to CandidateVotesDetailsType 
  // EX : 101 to {101, [list of voters address], total_voters_count}
  mapping(uint256 => CandidateVotesDetailsType) candidateVotes;

  // Which Voter voted for Whom -> voterAddress to Candidate
  mapping (address => uint256) public addressToCandidate;
  
  function vote(uint256 _voteToCandidate) public returns (bool) {

      require(_voteToCandidate > 100 && _voteToCandidate <= 105, "Invalid Votes");

      addressToCandidate[msg.sender] = _voteToCandidate;
      CandidateVotesDetailsType storage candidateDetail = candidateVotes[_voteToCandidate];
      candidateDetail.voterAddresses.push(msg.sender);
      candidateDetail.totalVote += 1;
      return true;
  }

  function getCandidateDetailsForAGivenId(uint256 _candidateId)public view returns (
        address[] memory voterAddresses, 
        uint256 totalVote
    ) {
    CandidateVotesDetailsType storage candidate = candidateVotes[_candidateId];
    return (
        candidate.voterAddresses, 
        candidate.totalVote
    );
  }
}