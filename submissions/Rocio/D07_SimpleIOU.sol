// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract IOU {

    // Mapping para registrar el saldo de ETH que cada usuario ha depositado.
    mapping(address => uint) public balances;

    // Mapping anidado (nested mapping) para registrar las deudas.
    // El formato es: deudor => acreedor => monto adeudado (en Wei)
    mapping(address => mapping(address => uint)) private debts;

    // 'payable' es esencial para que esta función pueda recibir criptomoneda.
    function deposit() external payable {
        // Añadimos el ETH enviado (msg.value) al saldo del remitente (msg.sender).
        balances[msg.sender] += msg.value;
    }

    /// @param _creditor La dirección del amigo a quien se le debe.
    /// @param _amount La cantidad de ETH (en Wei) que se le debe.
    function logIOU(address _creditor, uint _amount) external {
        // Requerir que no te registres una deuda a ti mismo.
        require(msg.sender != _creditor, "No puedes registrar una deuda contigo mismo.");
        require(_amount > 0, "El monto de la deuda debe ser mayor a cero.");

        // Registramos la deuda en el mapping anidado.
        // La deuda ahora es de msg.sender hacia _creditor.
        debts[msg.sender][_creditor] += _amount;
    }

    /// La cantidad a pagar es el total registrado en el sistema.
    /// @param _creditor La dirección del amigo a quien le vas a pagar.
    function settleDebt(address _creditor) external {
        // Obtenemos la cantidad de la deuda a saldar.
        uint amountToSettle = debts[msg.sender][_creditor];

        // 1. Validaciones
        require(amountToSettle > 0, "No tienes una deuda con este amigo.");
        require(balances[msg.sender] >= amountToSettle, "No tienes suficiente saldo para saldar esta deuda.");

        // 2. Efectos: Actualiza los saldos y deudas.
        // Reducimos el saldo del deudor (msg.sender).
        balances[msg.sender] -= amountToSettle;
        // Ponemos a cero la deuda.
        debts[msg.sender][_creditor] = 0;

        // 3. Interacciones: Transfiere el ETH al acreedor.
        // Usamos el patrón de transferencia recomendado (.call)
        (bool success, ) = payable(_creditor).call{value: amountToSettle}("");
        require(success, "La transferencia de pago fallo.");
    }
    
    /// @notice Retorna el saldo total de ETH que un usuario ha depositado.
    /// @param _user La dirección del usuario.
    /// @return El saldo total en Wei.
    function getUserBalance(address _user) external view returns (uint) {
        return balances[_user];
    }

    /// @notice Retorna el monto total que un deudor le debe a un acreedor específico.
    /// @param _debtor La dirección del deudor.
    /// @param _creditor La dirección del acreedor.
    /// @return El monto total de la deuda en Wei.
    function getDebt(address _debtor, address _creditor) external view returns (uint) {
        return debts[_debtor][_creditor];
    }
}