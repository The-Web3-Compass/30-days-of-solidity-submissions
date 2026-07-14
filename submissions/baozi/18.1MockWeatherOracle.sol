// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title MockWeatherOracle
/// @notice Simulates rainfall data as a Chainlink-compatible oracle for testing
contract MockWeatherOracle is AggregatorV3Interface, Ownable {
    uint8 private _decimals;
    string private _description;
    uint80 private _roundId;
    uint256 private _timestamp;
    uint256 private _lastUpdateBlock;

    constructor() Ownable(msg.sender) {
        _decimals = 0; // Rainfall in whole millimeters
        _description = "MOCK/RAINFALL/USD";
        _roundId = 1;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }

    // ========== Chainlink Interface ==========

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function description() external view override returns (string memory) {
        return _description;
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId_)
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
        return (_roundId_, _rainfall(), _timestamp, _timestamp, _roundId_);
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
        return (_roundId, _rainfall(), _timestamp, _timestamp, _roundId);
    }

    // ========== Internal Logic ==========

    /// @dev Generate pseudo-random rainfall using block data
    function _rainfall() internal view returns (int256) {
        uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;

        uint256 randomFactor = uint256(
            keccak256(abi.encodePacked(
                block.timestamp,
                block.coinbase,
                blocksSinceLastUpdate
            ))
        ) % 1000; // 0~999 mm

        return int256(randomFactor);
    }

    /// @dev Internal function to update state for next round
    function _updateRandomRainfall() private {
        _roundId++;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }

    // ========== Public Interface ==========

    /// @notice Manually trigger rainfall update (anyone can call)
    function updateRandomRainfall() external {
        _updateRandomRainfall();
    }
}
