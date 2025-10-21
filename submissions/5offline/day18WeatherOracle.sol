//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Oracles：预言者；信息源
//智能合约和外部世界是分离的，需要oracles把信息带进来
//chainlink 去中心化预言机的黄金标准，它为价格馈送、天气、随机性甚至整个数据网络提供 API
//两个合约：1模拟天气 2 农民保险

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//先导入chainlink和openzeppelin，这次是模拟天气，也可以真的做一个
//ownable之前写过了
 contract MockWeatherOracle is AggregatorV3Interface, Ownable {
    //继承两个连着写
    //写变量
    //抽象函数才不报错

    uint8 private _decimals;
    //降雨量以整毫米为单位，这里就是0
    string private _description;
    uint80 private _roundId;
    //每一天有不同的降雨量
    uint256 private _timestamp;
    //上一次更新数据的时间
    uint256 private _lastUpdateBlock;
    //上次更新发生的区块
    
    constructor() Ownable(msg.sender) {
        //继承open zeppelin要加入一些数据
    _decimals = 0;
    _description = "MOCK/RAINFALL/USD";
    _roundId = 1;
    //第一天
    _timestamp = block.timestamp;
    _lastUpdateBlock = block.number;
}
//因为是模拟天气函数所以辅助函数会比较多

function _rainfall() public view returns (int256) {
    //降雨量模拟功能

    uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;
    //相对于上一次更新，当前雨量-上一次更新的量
    uint256 randomFactor = uint256(keccak256(abi.encodePacked(
        //abi编码
        block.timestamp,
        block.coinbase,
        //返回当前区块的矿工（或验证者）的地址，用来“随机数”生成
        //block和coinbase固定搭配
        blocksSinceLastUpdate

    ))) % 1000;
    //哈希值取余数：在0-999mm之间，%取模运算符
    //是把这三个值一起编码成一个连续的字节流，而不是分别编码。


    return int256(randomFactor);
    //返回随机数
}
function _updateRandomRainfall() private {
    //现实生活中直接更新，这里手动模拟
    _roundId++;
    //新一天的量
    _timestamp = block.timestamp;
    _lastUpdateBlock = block.number;
    //更新的降雨量
}
function updateRandomRainfall() external {
    //大家都可以操作（最新数据之类的）
    _updateRandomRainfall();
}
//加入一些辅助函数
function getRoundData(uint80 _roundId_) external view override returns (
    uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
{
    return (_roundId_, _rainfall(), _timestamp, _timestamp, _roundId_);
}
//信息大集合，模拟数据输出
function latestRoundData() external view override returns (
    uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
{
    return (_roundId, _rainfall(), _timestamp, _timestamp, _roundId);
    //里面的内容和上一个一样
    //最新更新的数据

}
function decimals() external view override returns (uint8) {
    return _decimals;
    //openzeppelin要求的
}
function description() external view override returns (string memory) {
    return _description;}
    //根据上面的更改

        function version() external pure override returns (uint256) {
        return 1;
    }//mock版本1，这个是chain要求的

}





    
    









