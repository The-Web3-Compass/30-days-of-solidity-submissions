
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockWeatherOracle is AggregatorV3Interface, Ownable {//继承合约，Ownable 提供所权供能
    uint8 private _decimals;//定义数据的精度
    string private _description;//
    uint80 private _roundId;//用于模拟不同的数据更新周期（每一轮都是新的读数）
    uint256 private _timestamp;//记录上次更新发生的时间
    uint256 private _lastUpdateBlock;//跟踪上次更新发生时的块，用于添加随机性

    constructor() Ownable(msg.sender) {
        _decimals = 0; // Rainfall in whole millimeters
        _description = "MOCK/RAINFALL/USD";
        _roundId = 1;//从第一轮开始
        _timestamp = block.timestamp;//存储当前时间/区块以模拟数据的新鲜度
        _lastUpdateBlock = block.number;
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

    // Function to get current rainfall with random variation
    function _rainfall() public view returns (int256) {
        //这是一个叫做rainfall的函数，用来生成随机降雨量，返回一个随机值
        // Use block information to generate pseudo-random variation
        uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;//计算自上次更新以来的区块数
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(
            //keccak256(...)： 对这个字节串进行 Keccak-256 哈希运算
            //abi.encodePacked(...)： 将括号内的三个变量（block.timestamp、block.coinbase、blocksSinceLastUpdate）紧密地打包成一个字节串
            block.timestamp,//当前区块时间戳
            block.coinbase,//当前区块的矿工地址
            blocksSinceLastUpdate//自从上次更新以来的区块数
        ))) % 1000; // % 1000 (取模运算)： 这会返回 randomFactor 除以 1000 的余数。

        // Return random rainfall between 0 and 999mm
        return int256(randomFactor);//个介于 0 到 999 之间的整数
    }

    // Function to update random rainfall
    function _updateRandomRainfall() private {//这是一个叫做更新随机降雨量的函数，不返回数值 生成一个新的轮次ID和时间戳
        _roundId++;//轮次 ID 递增
        _timestamp = block.timestamp;//更新时间戳
        _lastUpdateBlock = block.number;//更新区块号
    }

    // Function to force update rainfall (anyone can call)
    function updateRandomRainfall() external {
        _updateRandomRainfall();
    }
}

