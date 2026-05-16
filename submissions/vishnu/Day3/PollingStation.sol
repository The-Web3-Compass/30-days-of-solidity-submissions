// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollingStation {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    
    Candidate[] public candidates;
    
    mapping(address => bool) public hasVoted;
    
    mapping(address => uint) public voterChoice;
    
    event VoteCast(address indexed voter, uint indexed candidateId, string candidateName);
    
    event CandidateAdded(uint indexed candidateId, string name);
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    

    function addCandidate(string memory _name) public onlyOwner {
        uint candidateId = candidates.length;
        candidates.push(Candidate({
            id: candidateId,
            name: _name,
            voteCount: 0
        }));
        
        emit CandidateAdded(candidateId, _name);
    }
    
    function vote(uint _candidateId) public {
        require(!hasVoted[msg.sender], "You have already voted");
        
        require(_candidateId < candidates.length, "Invalid candidate ID");
        
        hasVoted[msg.sender] = true;
        voterChoice[msg.sender] = _candidateId;
        candidates[_candidateId].voteCount++;
        
        emit VoteCast(msg.sender, _candidateId, candidates[_candidateId].name);
    }
    
    function getCandidateCount() public view returns (uint) {
        return candidates.length;
    }
    
    function getCandidate(uint _candidateId) public view returns (
        uint id, 
        string memory name, 
        uint voteCount
    ) {
        require(_candidateId < candidates.length, "Invalid candidate ID");
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.id, candidate.name, candidate.voteCount);
    }
    
    function getAllCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }
    
    function getWinner() public view returns (uint winnerId, string memory winnerName, uint winnerVotes) {
        require(candidates.length > 0, "No candidates available");
        
        uint highestVotes = 0;
        uint winner = 0;
        
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > highestVotes) {
                highestVotes = candidates[i].voteCount;
                winner = i;
            }
        }
        
        return (winner, candidates[winner].name, candidates[winner].voteCount);
    }
    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollingStation {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    
    Candidate[] public candidates;
    
    mapping(address => bool) public hasVoted;
    
    mapping(address => uint) public voterChoice;
    
    event VoteCast(address indexed voter, uint indexed candidateId, string candidateName);
    
    event CandidateAdded(uint indexed candidateId, string name);
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    

    function addCandidate(string memory _name) public onlyOwner {
        uint candidateId = candidates.length;
        candidates.push(Candidate({
            id: candidateId,
            name: _name,
            voteCount: 0
        }));
        
        emit CandidateAdded(candidateId, _name);
    }
    
    function vote(uint _candidateId) public {
        require(!hasVoted[msg.sender], "You have already voted");
        
        require(_candidateId < candidates.length, "Invalid candidate ID");
        
        hasVoted[msg.sender] = true;
        voterChoice[msg.sender] = _candidateId;
        candidates[_candidateId].voteCount++;
        
        emit VoteCast(msg.sender, _candidateId, candidates[_candidateId].name);
    }
    
    function getCandidateCount() public view returns (uint) {
        return candidates.length;
    }
    
    function getCandidate(uint _candidateId) public view returns (
        uint id, 
        string memory name, 
        uint voteCount
    ) {
        require(_candidateId < candidates.length, "Invalid candidate ID");
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.id, candidate.name, candidate.voteCount);
    }
    
    function getAllCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }
    
    function getWinner() public view returns (uint winnerId, string memory winnerName, uint winnerVotes) {
        require(candidates.length > 0, "No candidates available");
        
        uint highestVotes = 0;
        uint winner = 0;
        
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > highestVotes) {
                highestVotes = candidates[i].voteCount;
                winner = i;
            }
        }
        
        return (winner, candidates[winner].name, candidates[winner].voteCount);
    }
    
    function checkIfVoted(address _voter) public view returns (bool) {
        return hasVoted[_voter];
    }
    
    function getVoterChoice(address _voter) public view returns (uint candidateId, string memory candidateName) {
        require(hasVoted[_voter], "This address has not voted yet");
        uint choice = voterChoice[_voter];
        return (choice, candidates[choice].name);
    }
}

    function checkIfVoted(address _voter) public view returns (bool) {
        return hasVoted[_voter];
    }
    
    function getVoterChoice(address _voter) public view returns (uint candidateId, string memory candidateName) {
        require(hasVoted[_voter], "This address has not voted yet");
        uint choice = voterChoice[_voter];
        return (choice, candidates[choice].name);
    }
}
