// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importamos la implementación base y segura del estándar ERC20 de OpenZeppelin.

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title CustomToken
 * @dev Este contrato implementa un token ERC20 básico que puede ser transferido.
 * Hereda toda la lógica de transferencia y aprobación del contrato ERC20 de OpenZeppelin.
 */
contract CustomToken is ERC20 {
    // Definimos el número de tokens que se acuñarán inicialmente (1,000,000 tokens).
    // Usamos uint256 para manejar el valor después de aplicar los 18 decimales.
    uint256 private constant INITIAL_SUPPLY = 1_000_000 * 10**18;

    /**
     * @dev El constructor se ejecuta solo una vez, al desplegar el contrato.
     * @param initialOwner La dirección que recibirá todos los tokens iniciales.
     *
     * Inicializa:
     * 1. El nombre ("DevGeminiToken") y el símbolo ("DGT") del token.
     * 2. Acuña el total del suministro inicial y lo asigna a la dirección del desplegador.
     */
    constructor(address initialOwner) ERC20("DevGeminiToken", "DGT") {
        // La función _mint es una función interna del ERC20 de OpenZeppelin.
        // Se utiliza para crear nuevos tokens y asignarlos a una dirección.
        _mint(initialOwner, INITIAL_SUPPLY);
    }
}
