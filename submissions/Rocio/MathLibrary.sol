// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MathLibrary
 * @notice Contrato simple que ofrece funciones matematicas para otros contratos.
 */
contract MathLibrary {

    /// @notice Multiplica dos numeros enteros sin signo.
    /// @param a El primer operando.
    /// @param b El segundo operando.
    /// @return El resultado de la multiplicacion.
    function multiply(uint a, uint b) external pure returns (uint) {
        // Usamos 'pure' porque no leemos ni modificamos el estado del blockchain.
        return a * b;
    }
}