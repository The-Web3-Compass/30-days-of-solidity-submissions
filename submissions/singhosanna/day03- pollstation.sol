// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {

    string[] public candidateNames;
    mapping(string => uint256) private voteCount;
    mapping(address => bool) private hasVoted;
    mapping(address => string) private voterChoice;

    event CandidateAdded(string candidateName);
    event Voted(address indexed voter, string candidateName);

    function addCandidateNames(string memory _candidateName) public {
        candidateNames.push(_candidateName);
        voteCount[_candidateName] = 0;
        emit CandidateAdded(_candidateName);
    }

    function getCandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }

    function vote(string memory _candidateName) public {
        require(!hasVoted[msg.sender], "You have already voted!");
        require(voteCount[_candidateName] >= 0, "Candidate does not exist!");
        voteCount[_candidateName] += 1;
        hasVoted[msg.sender] = true;
        voterChoice[msg.sender] = _candidateName;
        emit Voted(msg.sender, _candidateName);
    }

    function getVote(string memory _candidateName) public view returns (uint256) {
        return voteCount[_candidateName];
    }

    function getVoterChoice(address _voter) public view returns (string memory) {
        require(hasVoted[_voter], "This address has not voted yet.");
        return voterChoice[_voter];
    }

    function getAllVotes() public view returns (uint256[] memory) {
        uint256[] memory votes = new uint256[](candidateNames.length);
        for (uint256 i = 0; i < candidateNames.length; i++) {
            votes[i] = voteCount[candidateNames[i]];
        }
        return votes;
    }

    function getWinner() public view returns (string memory winnerName, uint256 highestVotes) {
        require(candidateNames.length > 0, "No candidates available.");
        highestVotes = 0;
        winnerName = candidateNames[0];
        for (uint256 i = 0; i < candidateNames.length; i++) {
            uint256 count = voteCount[candidateNames[i]];
            if (count > highestVotes) {
                highestVotes = count;
                winnerName = candidateNames[i];
            }
        }
    }

    function getTotalVotes() public view returns (uint256 total) {
        for (uint256 i = 0; i < candidateNames.length; i++) {
            total += voteCount[candidateNames[i]];
        }
    }
}
