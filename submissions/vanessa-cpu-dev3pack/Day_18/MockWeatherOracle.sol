// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockWeatherOracle {
    uint80 private _roundId;
    int256 private _rainfallData; // In millimeters
    uint256 private _timestamp;

    constructor() {
        _roundId = 1;
        _timestamp = block.timestamp;
        _rainfallData = 100; // Default rainfall
    }

    function updateRainfall(int256 _rainfall) external {
        _rainfallData = _rainfall;
        _timestamp = block.timestamp;
        _roundId++;
    }

    // Mocking Chainlink's AggregatorV3Interface
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (_roundId, _rainfallData, _timestamp, _timestamp, _roundId);
    }
}