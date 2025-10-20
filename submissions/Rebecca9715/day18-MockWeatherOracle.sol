
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 调用chainlink中的，获取数据
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
//  基本包，无需再写ownable的代码，传入msg.sender即可。including an owner() and the onlyOwner modifier.
import "@openzeppelin/contracts/access/Ownable.sol";

// 从上述两个函数继承，并增加自己的逻辑
contract MockWeatherOracle is AggregatorV3Interface, Ownable {
    // 0，rainfall is in full millimeters
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
        // `block.number` 是一个特殊的全局变量，它表示当前区块的编号，每个区块都有一个唯一的编号，且随着新块的产生而递增。
        // 这里通过这种方式记录下当前操作发生的区块编号，后续可以用于一些与区块相关的逻辑判断，比如检查操作是否在一定区块范围内完成等。
        _lastUpdateBlock = block.number;
    }
// 以下为展示函数
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function description() external view override returns (string memory) {
        return _description;
    }

    function version() external pure override returns (uint256) {
        return 1;
    }
    // 输入一个_roundId_得到round的详情，是一个通用函数
    function getRoundData(uint80 _roundId_)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId_, _rainfall(), _timestamp, _timestamp, _roundId_);
    }
// 获取到最新的round数据，只把当前_roundId带入
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _rainfall(), _timestamp, _timestamp, _roundId);
    }

    // Function to get current rainfall with random variation
    // 随机生成一个降雨量
    function _rainfall() public view returns (int256) {
        // Use block information to generate pseudo-random variation
        uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            // 当前区块的矿工地址
            block.coinbase,
            // 上次更新以来经过的区块链数量
            blocksSinceLastUpdate
        ))) % 1000; // Random number between 0 and 999

        // Return random rainfall between 0 and 999mm
        return int256(randomFactor);
    }

    // Function to update random rainfall
    // 更新随机降雨数据
    function _updateRandomRainfall() private {
        _roundId++;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }

    // Function to force update rainfall (anyone can call)
    function updateRandomRainfall() external {
        _updateRandomRainfall();
    }
}

