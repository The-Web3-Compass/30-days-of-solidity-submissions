// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Un contador simple para demostrar la modificación de estado.
contract ClickCounter {
    // Declara una variable pública de tipo uint (entero sin signo)
    // El 'uint' por defecto es uint256. 'public' crea una función automática para leerla.
    uint public counter;

    /// @notice Incrementa el contador en uno.
    /// @dev Esta función modifica el estado del blockchain y, por lo tanto, cuesta gas.
    function click() external {
        counter = counter + 1; // O simplemente "counter++;"
    }

    /// @notice Retorna el valor actual del contador.
    /// @dev 'view' indica que la función no modifica el estado del contrato.
    /// No cuesta gas (solo por la llamada a la red).
    function getCounter() external view returns (uint) {
        return counter;
    }
}