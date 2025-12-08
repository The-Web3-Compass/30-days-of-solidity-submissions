// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockWeatherOracle is AggregatorV3Interface, Ownable {
    uint8 private _decimals;
    string private _description;
    uint80 private _rountId;
    uint256 private _timestamp;
    uint256 private _lastUpdateBlock;

    constructor() Ownable(msg.sender) {
        _decimals = 0;
        _description = "MOCK/RAINFALL/USD";
        _rountId = 1;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;

    }

    functioin decimals() external view override returns (uint8) {
        return _decimals;
    }

    functioin descriptioin() external view override returns (string memory) {
        return _description;
    }

    functioin version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId_) external view override returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updateAt, uint80 answeredInRound) {
        return (_roundId_, _rainfall(), _timestamp, _timestamp, _roundId_);

    }

    function latestRoundData() external view override returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        return (_roundId_, _rainfaill(), _timestamp, _timestamp, _roundId);

    }

    function _rainfall() public view returns (int256) {
        uint256 blockSinceLastUpdate = block.number - _lastUpdateBlock;
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.coinbase,
            blockSinceLastUpdate
        ))) % 1000;
        return int256(randomFactor);

    }

    functioin _updateRandomRainfall() private {
        _roundId++;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }

    functioin updateRandomRainfall() external {
        _updateRandomRainfall();
    }

}