// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IAggregatorV3.sol";

contract MockOracle is IAggregatorV3 {
    int256 public price;
    uint256 public updatedAt;

    constructor(int256 _price) {
        price = _price;
        updatedAt = block.timestamp;
    }

    function setPrice(int256 _price) external {
        price = _price;
        updatedAt = block.timestamp;
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 _updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, price, 0, updatedAt, 0);
    }
}