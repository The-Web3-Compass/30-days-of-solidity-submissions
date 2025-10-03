// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UserProfile {
    // 1. Declaración de variables de estado (Storage)
    // Estas variables almacenan permanentemente los datos en la blockchain.
    string private userName;
    string private userBio;

    // --------------------------------------------------------------------------

    function setProfile(string memory _name, string memory _bio) external {
        // Asignación de los valores de la memoria a las variables de almacenamiento.
        // Esto cambia el estado del contrato.
        userName = _name;
        userBio = _bio;
    }

    function getProfile() external view returns (string memory, string memory) {
        // Retorna los valores almacenados.
        return (userName, userBio);
    }
}