// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockWeatherOracle is AggregatorV3Interface, Ownable {
    uint8 private _decimals;
    string private _description;
    uint80 private _roundId;
    uint256 private _timestamp;
    uint256 private _lastUpdateBlock;

    constructor() Ownable(msg.sender) {
        _decimals = 0; // 降水量(单位为毫米)
        _description = "MOCK/RAINFALL/USD";
        _roundId = 1;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }

    // 返回精度
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    // 返回描述
    function description() external view override returns (string memory) {
        return _description;
    }

    // 返回版本
    function version() external pure override returns (uint256) {
        return 1;
    }

    // 获取轮次数据
    function getRoundData(uint80 _roundId_) external view override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId_, _rainfall(), _timestamp, _timestamp, _roundId_);
    }

    // 获取最新数据
    function latestRoundData() external view override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _rainfall(), _timestamp, _timestamp, _roundId);
    }

    // 通过随机变量获取当前降雨量
    function _rainfall() public view returns (int256) {
        uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;
        return int256(uint256(keccak256(abi.encodePacked(block.timestamp, block.coinbase, blocksSinceLastUpdate))) % 1000);
    }

    // 更新随机降雨量
    function _updateRandomRainfall() private {
        _roundId++;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }

    // 更新降雨量
    function updateRandomRainfall() external {
        _updateRandomRainfall();
    }
}