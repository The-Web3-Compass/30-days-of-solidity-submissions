// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importamos la Interfaz del contrato de servicio (MathLibrary).
// Esto le dice al compilador cómo se ve el contrato externo.
// Nota: En la misma carpeta no se requiere import, pero lo incluimos por buenas practicas.
// Aquí simulamos que la Interfaz ya está definida.
interface IMathLibrary {
    // Solo necesitamos la firma de la función que vamos a llamar.
    function multiply(uint a, uint b) external view returns (uint);
}

/**
 * @title Calculator
 * @notice Contrato que interactua con el MathLibrary para delegar el calculo.
 */
contract Calculator {
    // 1. Almacenar la direccion del contrato externo.
    address public mathLibraryAddress;
    
    // 2. Almacenar el resultado para demostrar que la llamada funciono.
    uint public lastResult;

    /// @notice Constructor que recibe la direccion del MathLibrary ya desplegado.
    /// @param _mathLibraryAddress La direccion del contrato MathLibrary.
    constructor(address _mathLibraryAddress) {
        require(_mathLibraryAddress != address(0), "Direccion de libreria invalida.");
        mathLibraryAddress = _mathLibraryAddress;
    }

    /// @notice Llama al contrato MathLibrary para calcular la multiplicacion.
    /// @param x El primer numero a multiplicar.
    /// @param y El segundo numero a multiplicar.
    function calculateProduct(uint x, uint y) external {
        
        // --- LA MAGIA DE LA INTERACCIÓN ENTRE CONTRATOS ---
        
        // 1. Casteo de la Direccion: Tomamos la 'address' almacenada
        // y la "convertimos" al tipo de Interfaz (IMathLibrary).
        // Esto le permite a Solidity tratar la direccion como una instancia del contrato.
        IMathLibrary mathLibrary = IMathLibrary(mathLibraryAddress);

        // 2. Llamada Externa: Llamamos a la funcion 'multiply' en la instancia.
        // El flujo de control se transfiere temporalmente a MathLibrary.sol.
        uint product = mathLibrary.multiply(x, y);

        // 3. Almacenamos el resultado.
        lastResult = product;
    }
}
