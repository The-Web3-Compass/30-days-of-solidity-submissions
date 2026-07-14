// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Simulates rainfall data updates

contract MockWeatherOracle {
    uint80 private _roundId;
    int256 private _rainfallData; // in millimeters
    uint256 private _timestamp;
    address private immutable _owner;

    constructor() {
        _owner = msg.sender;
        _roundId = 1;
        _timestamp = block.timestamp;
        _rainfallData = 100; // default rainfall
    }

    function updateRainfall(int256 _rainfall) external {
        require(msg.sender == _owner, "Only owner can update rainfall");
        _rainfallData = _rainfall;
        _timestamp = block.timestamp;
        _roundId++;
    }

    // Simulating Chainlink's AggregatorV3Interface
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