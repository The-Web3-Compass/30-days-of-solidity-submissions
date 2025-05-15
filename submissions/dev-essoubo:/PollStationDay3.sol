// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SimplePollingStation {
    // Structure pour stocker les informations des candidats
    struct Candidate {
        string name;
        uint256 voteCount;
    }
    
    // Liste des candidats
    Candidate[] public candidates;
    
    // Mapping pour suivre qui a voté
    mapping(address => bool) public hasVoted;
    
    // Mapping pour suivre pour qui chaque électeur a voté
    mapping(address => uint) public voterToCandidate;
    
    // L'adresse du propriétaire du contrat
    address public owner;
    
    // Événement émis lorsqu'un vote est enregistré
    event VoteCast(address indexed voter, uint candidateId);
    
    constructor() {
        owner = msg.sender;
    }
    
    // Fonction pour ajouter un candidat (réservée au propriétaire)
    function addCandidate(string memory _name) public {
        require(msg.sender == owner, "Only the owner can add candidates");
        candidates.push(Candidate({
            name: _name,
            voteCount: 0
        }));
    }
    
    // Fonction pour voter pour un candidat
    function vote(uint _candidateId) public {
        // Vérifier que l'électeur n'a pas déjà voté
        require(!hasVoted[msg.sender], "You have already voted");
        
        // Vérifier que le candidat existe
        require(_candidateId < candidates.length, "Invalid candidate ID");
        
        // Enregistrer le vote
        hasVoted[msg.sender] = true;
        voterToCandidate[msg.sender] = _candidateId;
        candidates[_candidateId].voteCount++;
        
        // Émettre l'événement
        emit VoteCast(msg.sender, _candidateId);
    }
    
    // Fonction pour obtenir le nombre de candidats
    function getCandidateCount() public view returns (uint) {
        return candidates.length;
    }
    
    // Fonction pour obtenir les informations d'un candidat
    function getCandidate(uint _candidateId) public view returns (string memory name, uint256 voteCount) {
        require(_candidateId < candidates.length, "Invalid candidate ID");
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.name, candidate.voteCount);
    }
    
    // Fonction pour vérifier pour qui un électeur a voté
    function getVotedCandidate(address _voter) public view returns (uint) {
        require(hasVoted[_voter], "This address has not voted yet");
        return voterToCandidate[_voter];
    }
}