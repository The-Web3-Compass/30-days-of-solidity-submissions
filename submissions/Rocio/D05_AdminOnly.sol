// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TreasureChest {

    // Dirección del dueño actual del Cofre. Solo el dueño tiene privilegios de administración.
    address public owner;

    // Mapping para rastrear el monto que el dueño ha aprobado para un usuario específico.
    // Mapea la dirección del usuario a la cantidad (en Wei) que pueden retirar.
    mapping(address => uint) public allowance;

    modifier onlyOwner() {
        // 'require' verifica que la dirección que llama (msg.sender) sea el dueño.
        require(msg.sender == owner, "Solo el dueno puede ejecutar esta accion.");
        // El guion bajo (_) es crucial; indica dónde se inserta el código de la función.
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        // No se necesita logica adicional; el Ether se añade al balance del contrato.
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Direccion de nuevo dueno invalida.");
        owner = _newOwner;
    }

    function approveWithdrawal(address _spender, uint _amount) external onlyOwner {
        allowance[_spender] = _amount;
    }

    function ownerWithdraw(uint _amount) external onlyOwner {
        // Requerir que el Cofre tenga suficiente Ether.
        require(address(this).balance >= _amount, "Fondos insuficientes en el Cofre.");

        // Transfiere los fondos al dueño.
        payable(owner).transfer(_amount);
    }

    function withdrawApproved() external {
        uint amountToWithdraw = allowance[msg.sender];

        // Validación 1: El usuario debe tener una asignación aprobada.
        require(amountToWithdraw > 0, "No tienes una asignacion aprobada para retirar.");
        
        // Validación 2: El contrato debe tener suficientes fondos.
        require(address(this).balance >= amountToWithdraw, "Fondos insuficientes en el Cofre.");

        // Elimina el permiso de retiro inmediatamente para evitar doble gasto.
        allowance[msg.sender] = 0; 

        // Transfiere los fondos al usuario que llama (msg.sender).
        payable(msg.sender).transfer(amountToWithdraw);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}