//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Pollstation{


    struct Candidate{
        string name;
        uint256 voteCount;
    }

    Candidate[] public candidates;

    mapping(uint256 => Candidate) public votes;
    mapping(address => bool) public hasVoted;


    function addCandidate(string memory _candidate) public {
        candidates.push(Candidate(_candidate, 0));
    }

    function vote(uint256 _candidateID) public {
        require(hasVoted[msg.sender] == false, "Already voted"); 
        votes[_candidateID] = Candidate(candidates[_candidateID].name, votes[_candidateID].voteCount++); 
        hasVoted[msg.sender] = true;
    }

    function getVotes(uint256 _candidateID) public view returns(uint256){
        return votes[_candidateID].voteCount;
    }

}