// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PollingStation {

    struct Candidate {
        string name;
        uint voteCount;
    }

    Candidate[] public candidates;

    mapping(address => uint) private hasVoted; // 0 significa que no ha votado

    function addCandidate(string memory _name) public {
        // Agrega un nuevo struct Candidate al array 'candidates'.
        candidates.push(Candidate({
            name: _name,
            voteCount: 0 // Inicia siempre en cero
        }));
    }

    function vote(uint _candidateId) external {
        // Validación 1: El votante no debe haber votado previamente.
        // La address 'msg.sender' es la que inicia la transacción.
        require(hasVoted[msg.sender] == 0, "Ya has emitido tu voto.");

        // Validación 2: El ID del candidato debe existir.
        // Debe ser menor que el tamaño del array 'candidates'.
        require(_candidateId < candidates.length, "ID de candidato invalido.");

        // 1. Registra el voto en el historial (MAPPING).
        // Almacena el ID del candidato (+1 para que 0 siga significando 'no votado').
        hasVoted[msg.sender] = _candidateId + 1;

        // 2. Incrementa el contador de votos (ARRAY).
        candidates[_candidateId].voteCount++;
    }

    function getCandidatesCount() external view returns (uint) {
        return candidates.length;
    }

    function checkVoterHistory(address _voterAddress) external view returns (uint) {
        // Restamos 1 para devolver el ID del array, o 0 si no ha votado.
        if (hasVoted[_voterAddress] > 0) {
            return hasVoted[_voterAddress] - 1;
        }
        return 0; // 0 o cualquier valor que designes como 'no ha votado'
    }
}