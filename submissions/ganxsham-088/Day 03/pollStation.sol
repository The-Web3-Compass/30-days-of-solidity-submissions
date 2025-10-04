pragma solidity ^0.8.30;


/**
 * @title PollStation
 * @dev A simple polling contract where users can vote for candidates. Each user can vote only once and their vote is recorded.
 */
contract PollStation {
    // Candidate structure to hold candidate details
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    Candidate[] public candidates; // Array to hold all candidates
    mapping(address => bool) public hasVoted; // Mapping to track if an address has voted
    mapping(address => string) public candidateVotedFor; // Mapping to track which candidate an address voted for

    // Function to add a new candidate
    function addCandidate(string memory _name) public {
        candidates.push(Candidate({name: _name, voteCount: 0}));
    }

    // Function to vote for a candidate by index
    function vote(uint256 _candidateIndex) public {
        require(!hasVoted[msg.sender], "You have already voted.");
        require(_candidateIndex < candidates.length, "Invalid candidate index.");

        candidateVotedFor[msg.sender] = candidates[_candidateIndex].name;
        candidates[_candidateIndex].voteCount += 1;
        hasVoted[msg.sender] = true;
    }

    // Function to get candidate details by index
    function getCandidate(uint256 _index) public view returns (string memory, uint256) {
        require(_index < candidates.length, "Invalid candidate index.");
        Candidate memory candidate = candidates[_index];
        return (candidate.name, candidate.voteCount);
    }
}