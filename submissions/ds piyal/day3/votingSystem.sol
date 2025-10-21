// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

contract VotingSystem {
 
    string[] public CandidateNames;
    mapping (string => uint256) public Votecount;
    mapping(address => bool) public hasVoted;
    mapping(string => bool) public candidateExists;
    
    uint256 public totalVotes;
    
    event CandidateAdded(string candidateName);
    event VoteCast(address voter, string candidateName);

    function AddCandidateNames (string memory _CandidateNames) public {
        require(!candidateExists[_CandidateNames], "Candidate already exists");
        require(bytes(_CandidateNames).length > 0, "Candidate name cannot be empty");

        CandidateNames.push(_CandidateNames);
        Votecount[_CandidateNames] = 0;
        candidateExists[_CandidateNames] = true;
         emit CandidateAdded(_CandidateNames);
    }
    
    function GetCandidateNames() public view returns(string[] memory){
        return CandidateNames;
    }

    function Vote(string memory _CandidateName) public {
        require(!hasVoted[msg.sender], "You have already voted");
        require(candidateExists[_CandidateName], "Candidate does not exist");
        
        Votecount[_CandidateName] += 1;
        hasVoted[msg.sender] = true;
        
        totalVotes += 1;
        
        emit VoteCast(msg.sender, _CandidateName);
    }

    function GetVote(string memory _candidateName) public view returns (uint256) {
        return Votecount[_candidateName];
    }
    
    function CheckIfVoted(address _voter) public view returns (bool) {
        return hasVoted[_voter];
    }
    
    function CheckCandidateExists(string memory _candidateName) public view returns (bool) {
        return candidateExists[_candidateName];
    }
    
    function GetTotalVotes() public view returns (uint256) {
        return totalVotes;
    }
    
    function GetAllResults() public view returns (string[] memory, uint256[] memory) {
        uint256[] memory votes = new uint256[](CandidateNames.length);
        
        for (uint256 i = 0; i < CandidateNames.length; i++) {
            votes[i] = Votecount[CandidateNames[i]];
        }
        
        return (CandidateNames, votes);
    }
    
    function GetWinner() public view returns (string memory winnerName, uint256 winnerVotes) {
        require(CandidateNames.length > 0, "No candidates available");
        
        winnerName = CandidateNames[0];
        winnerVotes = Votecount[CandidateNames[0]];
        
        for (uint256 i = 1; i < CandidateNames.length; i++) {
            if (Votecount[CandidateNames[i]] > winnerVotes) {
                winnerName = CandidateNames[i];
                winnerVotes = Votecount[CandidateNames[i]];
            }
        }
    }
    
    function GetCandidateCount() public view returns (uint256) {
        return CandidateNames.length;
    }
}