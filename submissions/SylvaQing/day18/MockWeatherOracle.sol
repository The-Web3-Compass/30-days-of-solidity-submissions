// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
- **继承** `AggregatorV3Interface` — 这意味着它必须实现`latestRoundData()`等函数。
- **继承** `Ownable` — 因此我们可以免费获得所有权功能。
*/
contract MockWeatherOracle is AggregatorV3Interface, Ownable{
    uint8 private _decimals; //数据的精度
    string private _description; //Feed 的文字标签
    uint80 private _roundId; //模拟不同的数据更新周期
    uint256 private _timestamp; //记录上次更新发生的时间
    uint256 private _lastUpdateBlock; //跟踪上次更新发生时的块

    constructor() Ownable(msg.sender) {
        _decimals = 0; // 降雨不需要小数
        _description = "MOCK/RAINFALL/USD"; 
        _roundId = 1; //从第 1 轮开始 
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }
    // ====== 接口函数 ====== //
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function description() external view override returns (string memory) {
        return _description;
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    // 舍入数据函数,模拟了 Chainlink 访问历史数据的标准功能
     function getRoundData(uint80 _roundId_)external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
     ){
        return (_roundId_, _rainfall(), _timestamp, _timestamp, _roundId_);
     }


    //  应用程序使用它来获取最新数据
     function latestRoundData() external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
     ){
        return (_roundId, _rainfall(), _timestamp, _timestamp, _roundId);
     }
    

    //  模拟降雨发生器
     function _rainfall() public view returns (int256){
        uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.coinbase, //矿工地址（一些熵）
            blocksSinceLastUpdate
        ))) % 1000;

        return int256(randomFactor);
    }
    // 辅助函数：增加轮数、记录新数据的创建时间
     function _updateRandomRainfall()private {
        _roundId++;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
     }
    //  任何人都可以调用的 public 函数来更新“预言机”数据
     function updateRandomRainfall() external{
        _updateRandomRainfall();
     }
}