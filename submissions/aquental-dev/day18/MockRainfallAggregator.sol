// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

// Mock AggregatorV3Interface for simulating rainfall data on Sepolia testnet
contract MockRainfallAggregator is Ownable {
    // Struct to store round data
    struct RoundData {
        uint80 roundId;
        int256 rainfall;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    // Latest round data
    RoundData public latestData;
    uint80 public currentRoundId;

    // Constructor initializes with an initial rainfall value
    constructor(int256 _initialRainfall) Ownable(msg.sender) {
        latestData = RoundData({
            roundId: 1,
            rainfall: _initialRainfall,
            startedAt: block.timestamp,
            updatedAt: block.timestamp,
            answeredInRound: 1
        });
        currentRoundId = 1;
    }

    // Returns the latest round data, compatible with AggregatorV3Interface
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 rainfall,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            latestData.roundId,
            latestData.rainfall,
            latestData.startedAt,
            latestData.updatedAt,
            latestData.answeredInRound
        );
    }

    // Allows owner to update simulated rainfall data
    function setRainfall(int256 _rainfall) external onlyOwner {
        require(_rainfall >= 0, "Rainfall cannot be negative");
        currentRoundId++;
        latestData = RoundData({
            roundId: currentRoundId,
            rainfall: _rainfall,
            startedAt: block.timestamp,
            updatedAt: block.timestamp,
            answeredInRound: currentRoundId
        });
    }

    // Returns the decimals for rainfall data (mocked as 0 for simplicity)
    function decimals() external pure returns (uint8) {
        return 0; // Rainfall in mm, no decimals
    }

    // Returns the description of the data feed
    function description() external pure returns (string memory) {
        return "Mock Rainfall Data Feed (mm)";
    }

    // Returns the version of the aggregator
    function version() external pure returns (uint256) {
        return 3; // Matches AggregatorV3Interface
    }
}
