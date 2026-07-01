// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PiggyBank {
    // Mapping que almacena los saldos de cada usuario.
    // La clave es la dirección del usuario (address) y el valor es su saldo (uint, en Wei).
    mapping(address => uint) private balances;

    function deposit() external payable {
        // 'msg.sender' es la dirección que llama a la función (el usuario).
        // 'msg.value' es la cantidad de Ether (en Wei) que se envía en la transacción.

        // Añadimos el valor enviado al saldo del usuario en el mapping.
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        // 1. Obtener la cantidad que el usuario intentará retirar.
        uint amountToWithdraw = balances[msg.sender];

        // 2. Validación: Asegurar que hay algo para retirar.
        require(amountToWithdraw > 0, "No tienes fondos para retirar.");

        // 3. Establecer el saldo del usuario a cero ANTES de la transferencia.
        // Esto es una práctica de seguridad crítica para prevenir el ataque de reentrada.
        balances[msg.sender] = 0;

        // 4. Transferir el Ether al usuario.
        // Convertimos la dirección del usuario a 'payable' para poder enviar ETH.
        // Usamos '.call' como el método de transferencia recomendado en Solidity moderno.
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        
        // 5. Validación final: si la transferencia falló, revertir.
        require(success, "La transferencia de Ether fallo.");
    }

    function getBalance() external view returns (uint) {
        return balances[msg.sender];
    }
}
