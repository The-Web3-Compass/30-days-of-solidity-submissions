// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockWeatherOracle
 * @dev Simulates a Chainlink oracle that returns rainfall data for local testing.
 */
contract MockWeatherOracle is AggregatorV3Interface, Ownable {
    uint8 private _decimals = 0;
    string private _description = "Mock Rainfall Oracle";
    uint256 private _timestamp;
    uint80 private _roundId = 1;
    int256 private _latestRainfall;
    uint256 private _lastUpdateBlock;

    constructor() Ownable(msg.sender) {
        _updateRandomRainfall();
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function description() external view override returns (string memory) {
        return _description;
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 roundId_)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (roundId_, _latestRainfall, _timestamp, _timestamp, roundId_);
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (_roundId, _latestRainfall, _timestamp, _timestamp, _roundId);
    }

    function _updateRandomRainfall() private {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.difficulty, msg.sender)
            )
        ) % 1000; // Rainfall range: 0–999 mm

        _latestRainfall = int256(random);
        _timestamp = block.timestamp;
        _roundId++;
        _lastUpdateBlock = block.number;
    }

    /// @notice Public method to simulate a new rainfall update
    function updateRandomRainfall() external {
        _updateRandomRainfall();
    }

    /// @notice Returns the latest rainfall (for frontend debug)
    function getLastRainfall() external view returns (int256) {
        return _latestRainfall;
    }
}