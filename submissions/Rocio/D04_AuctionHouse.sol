// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract SimpleAuction {
    // Mantiene la dirección del postor actual con la puja más alta.
    address public highestBidder;
    // Mantiene el valor de la puja más alta (en Wei).
    uint public highestBid;

    // Dirección del creador del contrato (quien recibe el dinero).
    address public beneficiary;

    // Momento en que termina la subasta (en formato Unix timestamp).
    uint public auctionEndTime;

    constructor(uint _biddingTime) {
        beneficiary = msg.sender;
        // Establece la hora de finalización usando el tiempo actual de la blockchain.
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid() external payable {
        // Validación 1: El tiempo es clave. La subasta debe seguir activa.
        // 'require' es la forma en que Solidity implementa el control de errores.
        require(block.timestamp < auctionEndTime, "La subasta ya ha terminado.");

        // Validación 2: La puja actual debe ser mayor que la puja más alta registrada.
        require(msg.value > highestBid, "Tu puja debe ser mayor que la puja actual.");

        // Lógica de Reembolso (Simplificado):
        // En una subasta real, el dinero del postor anterior se enviaría a una
        // variable de 'refunds'. Para este ejemplo simple, solo reemplazaremos el valor.
        
        // Actualización de estado: El postor actual y la puja más alta.
        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function endAuction() external {
        // Validación 1: La subasta ya debe haber terminado.
        require(block.timestamp >= auctionEndTime, "La subasta no ha terminado aun.");

        // Validación 2: Se asegura de que solo se pueda finalizar una vez.
        // Usamos la variable 'highestBid' como un interruptor de estado.
        require(highestBid > 0, "No se puede finalizar si no hay pujas.");

        // IF/ELSE LÓGICA DE FINALIZACIÓN:
        if (highestBidder != address(0)) {
            // Envía los fondos al beneficiario.
            payable(beneficiary).transfer(highestBid);
            
            // Marca el estado como "finalizado" para evitar llamadas futuras.
            highestBid = 0; 
        } else {
             // Este 'else' cubre el raro caso de que se intente finalizar sin pujas.
             // Aquí no hace nada, pero en un contrato real manejarías reembolsos.
             highestBid = 0;
        }
    }
}
