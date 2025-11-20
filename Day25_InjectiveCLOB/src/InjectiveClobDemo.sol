// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IClobModule.sol";


contract InjectiveClobDemo {
    
    IClobModule private constant CLOB = IClobModule(0x0000000000000000000000000000000000000000);

    event OrderPlaced(bytes32 orderId);
    event OrderCancelled(bytes32 orderId, bool ok);

    function place(
        address market,
        bool isBuy,
        uint256 price,
        uint256 quantity
    ) external returns (bytes32 id) {
        
        id = CLOB.placeOrder(market, isBuy, price, quantity);
        emit OrderPlaced(id);
    }

    function cancel(bytes32 orderId) external returns (bool ok) {
        ok = CLOB.cancelOrder(orderId);
        emit OrderCancelled(orderId, ok);
    }

    function read(bytes32 orderId)
        external
        view
        returns (
            address market,
            address owner,
            bool isBuy,
            uint256 price,
            uint256 quantity,
            uint256 filled
        )
    {
        return CLOB.getOrder(orderId);
    }
}
