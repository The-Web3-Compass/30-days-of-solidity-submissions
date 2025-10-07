// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Poll {

    address public admin; 
    string[] public candidates; 

    mapping(string => uint256) private voteCount; 
    // mapping(address => bool) public hasVoted; 
    mapping(address => mapping(string => bool)) public hasVotedForCandidate; // now a single voter can vote once for multiple person 


    event CandidateAdded(string candidate);
    event VoteCast(address voter, string candidate);

    constructor() {
        admin = msg.sender; // Set deployer as admin
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    function addCandidate(string memory _candidateName) public onlyAdmin {
        candidates.push(_candidateName);
        voteCount[_candidateName] = 0;
        emit CandidateAdded(_candidateName);
    }

    // Allows a user to vote for a candidate once
    function vote(string memory _candidateName) public {
        // require(!hasVoted[msg.sender], "You have already voted");
        require(!hasVotedForCandidate[msg.sender][_candidateName], "You have already voted for this candidate");
        require(candidateExists(_candidateName), "Candidate does not exist");

        voteCount[_candidateName]++;
        // hasVoted[msg.sender] = true;
        hasVotedForCandidate[msg.sender][_candidateName] = true;

        emit VoteCast(msg.sender, _candidateName);
    }

    // Get all candidates
    function getCandidates() public view returns (string[] memory) {
        return candidates;
    }

    // Get vote count for a specific candidate
    function getVoteCount(string memory _candidateName) public view returns (uint256) {
        require(candidateExists(_candidateName), "Candidate does not exist");
        return voteCount[_candidateName];
    }

    // Check if a candidate exists
    function candidateExists(string memory _candidateName) internal view returns (bool) {
        for (uint256 i = 0; i < candidates.length; i++) {
            if (keccak256(abi.encodePacked(candidates[i])) == keccak256(abi.encodePacked(_candidateName))) {
                return true;
            }
        }
        return false;
    }
}
