// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OptimizedMockWeatherOracle is AggregatorV3Interface, Ownable {
    // Using `immutable` saves gas by storing the value directly in the bytecode, avoiding SLOAD operations. `public` automatically creates a getter function.
    uint8 public immutable override decimals;
    string public immutable override description;

    // Using `constant` is the most gas-efficient way to store a fixed value known at compile time.
    uint256 public constant override version = 1;

    uint80 private _roundId;
    uint256 private _timestamp;
    uint256 private _lastUpdateBlock;

    constructor() Ownable(msg.sender) {
        decimals = 0; // Rainfall in whole millimeters
        description = "MOCK/RAINFALL/USD";
        _roundId = 1;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }

    function getRoundData(uint80 _roundId_)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId_, _rainfall(), _timestamp, _timestamp, _roundId_);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _rainfall(), _timestamp, _timestamp, _roundId);
    }

    function _rainfall() internal view returns (int256) {
        uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;
        // Generate a pseudo-random number between 0 and 999
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.coinbase,
            blocksSinceLastUpdate
        ))) % 1000;

        return int256(randomFactor);
    }

    function updateRandomRainfall() external {
        _roundId++;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }
}