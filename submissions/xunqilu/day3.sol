// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    string[] public candidateNames;
    mapping(string => uint256) public votes;
    mapping(address => bool) public hasVoted; // check if an address has voted
    mapping(string => bool) public candidateRegistered; // check if candidate exist
    
    function addCandidateName(string memory _candidateName) public {
        require(!candidateRegistered[_candidateName], "Candidate already exists"); 
        candidateNames.push(_candidateName);
        votes[_candidateName] = 0;
        candidateRegistered[_candidateName] = true;
    }

    
    function getCandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }

    
    function vote(string memory _candidateName) public {
        // prevent duplicate vote
        require(!hasVoted[msg.sender], "You have already voted"); // when has vote of the address is false, then keep running the code
                                                                   // if has vote of the address is true, then throw error

        //check if the candidate exists
        require(candidateRegistered[_candidateName], "Candidate does not exist");

        votes[_candidateName] += 1;
        hasVoted[msg.sender] = true; // mark the address has voted
    }

 
    function getVote(string memory _candidateName) public view returns (uint256) {
        return votes[_candidateName];
    }


    function getAllVotes() public view returns (string[] memory, uint256[] memory) {
        uint256[] memory allVotes = new uint256[](candidateNames.length);
        for (uint256 i = 0; i < candidateNames.length; i++) {
            allVotes[i] = votes[candidateNames[i]];
        }
        return (candidateNames, allVotes);
    }
}
