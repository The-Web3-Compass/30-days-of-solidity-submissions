// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IClobModule {
    
    function placeOrder(
        address market,
        bool isBuy,
        uint256 price,
        uint256 quantity
    ) external payable returns (bytes32 orderId);

    function cancelOrder(bytes32 orderId) external returns (bool ok);

    function getOrder(bytes32 orderId)
        external
        view
        returns (
            address market,
            address owner,
            bool isBuy,
            uint256 price,
            uint256 quantity,
            uint256 filled
        );
}
