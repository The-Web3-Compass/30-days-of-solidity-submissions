// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 引入 Chainlink 的 AggregatorV3 接口，用于兼容 Chainlink 数据格式（例如 latestRoundData()）
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// 引入 OpenZeppelin 的 Ownable，用于合约拥有者控制
import "@openzeppelin/contracts/access/Ownable.sol";

/*
📘 MockWeatherOracle（假天气预言机）
-----------------------------------------
这是一个“模拟天气数据”的合约，用来假装成 Chainlink 的天气数据预言机。
它实现了 AggregatorV3Interface 接口中的所有函数，因此可以被其他合约（比如 CropInsurance）当作标准喂价合约来使用。

特点：
兼容 Chainlink 接口
使用区块信息生成伪随机降雨量
可手动触发“更新天气”
*/
contract MockWeatherOracle is AggregatorV3Interface, Ownable {
    // ==========================
    // 基础状态变量
    // ==========================

    uint8 private _decimals;         // 小数位数（天气数据通常不需要小数，这里设为 0）
    string private _description;     // 数据描述，例如“MOCK/RAINFALL/USD”
    uint80 private _roundId;         // 模拟 Chainlink 的“数据轮次编号”
    uint256 private _timestamp;      // 数据时间戳
    uint256 private _lastUpdateBlock;// 上次更新的区块号

    // ==========================
    // 构造函数
    // ==========================
    constructor() Ownable(msg.sender) {
        _decimals = 0; // 降雨量单位为毫米，取整
        _description = "MOCK/RAINFALL/USD"; // 说明这个喂价代表“降雨量”
        _roundId = 1; // 第一轮
        _timestamp = block.timestamp; // 当前时间
        _lastUpdateBlock = block.number; // 当前区块号
    }

    // ==========================
    // 实现 Chainlink 接口要求的函数
    // ==========================

    // 返回小数位数
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    // 返回描述字符串
    function description() external view override returns (string memory) {
        return _description;
    }

    // 返回版本号（固定为 1）
    function version() external pure override returns (uint256) {
        return 1;
    }

    // 返回指定轮次的降雨数据（兼容 Chainlink 接口）
    function getRoundData(uint80 _roundId_)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        // 这里我们直接用伪随机生成的降雨量
        return (_roundId_, _rainfall(), _timestamp, _timestamp, _roundId_);
    }

    // 返回最近一轮的数据（CropInsurance 就是用这个函数拿“降雨量”）
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _rainfall(), _timestamp, _timestamp, _roundId);
    }

    // ==========================
    // ☔ 降雨量计算逻辑
    // ==========================

    /*
    _rainfall()
    模拟生成一个“当前降雨量”的伪随机数。
    范围为 0 ~ 999 毫米。
    */
    function _rainfall() public view returns (int256) {
        // 计算距离上次更新经历了多少个区块
        uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;

        // 使用区块信息生成伪随机数（⚠️ 不是安全随机，仅供测试）
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(
            block.timestamp,    // 当前时间戳
            block.coinbase,     // 出块者地址
            blocksSinceLastUpdate
        ))) % 1000; // 取 0~999 范围

        // 返回随机的降雨量（毫米）
        return int256(randomFactor);
    }

    // ==========================
    // 降雨数据更新函数
    // ==========================

    /*
    _updateRandomRainfall()
    内部私有函数，用于更新内部状态变量：
    - 增加轮次（_roundId）
    - 更新时间戳
    - 更新区块号
    */
    function _updateRandomRainfall() private {
        _roundId++;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }

    /*
    updateRandomRainfall()
    外部函数（public），任何人都可以调用。
    作用：触发一次“更新天气”的行为，相当于告诉系统“天气变了”。
    */
    function updateRandomRainfall() external {
        _updateRandomRainfall();
    }
}
