// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiCurrencyTipJar {

    // Simulamos un tipo de cambio fijo. Se utiliza 3000 para que 1 ETH equivalga a 3000 USD.
    // Usamos uint para la simplicidad del ejemplo.
    uint private constant ETH_TO_USD_RATE = 3000; // 1 ETH = 3000 USD

    // Dirección que recibirá todas las propinas en ETH.
    address payable public immutable owner;

    // 1. Mapeo para rastrear el total de ETH depositado por cada usuario (en Wei).
    mapping(address => uint) public ethTips;

    // 2. Mapeo para rastrear el total de propinas en el equivalente de USD (simulado).
    // Usamos una granularidad simple para representar los centavos de dólar.
    mapping(address => uint) public usdTipsEquivalent;

    /// @notice Establece al desplegador del contrato como el dueño (owner).
    constructor() {
        // Usamos 'payable' para que el dueño pueda recibir ETH.
        owner = payable(msg.sender);
    }

    /// @notice Permite al usuario enviar ETH real como propina.
    function tipInEth() external payable {
        // msg.value es la cantidad de ETH (en Wei) enviada.
        uint ethAmount = msg.value;
        require(ethAmount > 0, "Debe enviar una cantidad positiva de ETH.");

        // 1. Calcular el equivalente en USD (simulado)
        // La fórmula es: (ETH en Wei * Tasa USD) / 1 Ether (para ajustar las unidades)
        // 1 ether es 10^18 Wei.
        uint usdEquivalent = (ethAmount * ETH_TO_USD_RATE) / 1 ether;

        // 2. Actualizar el estado (almacenamiento)
        ethTips[msg.sender] += ethAmount;
        usdTipsEquivalent[msg.sender] += usdEquivalent;
    }

    /// @notice Permite al usuario simular una propina en USD (solo registra el valor, no envía ETH).
    /// @param _usdAmountSimulated La cantidad simulada en USD (usar unidades enteras, ej: 10 para $10 USD).
    function tipInSimulatedUSD(uint _usdAmountSimulated) external {
        require(_usdAmountSimulated > 0, "El monto simulado debe ser positivo.");

        // 1. Simplemente registramos la contribución en el mapping de USD.
        // No hay transferencia de ETH en esta función.
        usdTipsEquivalent[msg.sender] += _usdAmountSimulated;
    }

    /// @notice Permite al dueño retirar todo el ETH acumulado en el contrato.
    function withdrawTips() external {
        require(msg.sender == owner, "Solo el dueno puede retirar.");
        
        // Obtenemos el balance total del contrato.
        uint balance = address(this).balance;
        require(balance > 0, "No hay ETH para retirar.");

        // Transferimos todo el balance al dueño.
        // Usamos el metodo 'call' para transferencias modernas.
        (bool success, ) = owner.call{value: balance}("");
        require(success, "La transferencia fallo.");
    }

    /// @notice Retorna la contribución total de un usuario en USD simulado.
    /// @param _user La dirección del usuario a consultar.
    /// @return La cantidad total de propinas en el equivalente de USD simulado.
    function getUsdTipTotal(address _user) external view returns (uint) {
        return usdTipsEquivalent[_user];
    }
}