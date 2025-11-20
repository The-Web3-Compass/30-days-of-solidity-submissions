// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// Minimal Chainlink-like aggregator for local tests
contract MockV3Aggregator {
    uint8 public immutable decimals;
    int256 public answer;

    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        answer = _initialAnswer; // e.g., 2000_00000000 for $2000 with 8 decimals
    }

    function updateAnswer(int256 _new) external {
        answer = _new;
    }

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (0, answer, 0, 0, 0);
    }
}
