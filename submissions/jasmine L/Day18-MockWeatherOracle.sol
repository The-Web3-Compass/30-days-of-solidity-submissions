// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//相当于模拟了一个现实的降雨器，以方便我们基于现实数据的功能，后续如果有需要接入现实世界，可以替换
contract MockWeatherOracle is AggregatorV3Interface, Ownable{
    uint8 private _decimals;
    string private _description;
    uint80 private _roundId;
    uint256 private _timestamp;
    uint256 private _lastUpdateBlock;

    constructor() Ownable(msg.sender){
        _decimals = 0;
        _description = "MOCK/RAINFALL/USD";
        _roundId = 1;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }
    function decimals() external view override returns(uint8){
        return _decimals;
    }
    function description() external  view  override  returns(string memory){
        return _description;
    }
    function version() external pure override returns  (uint256){
        return 1;
    }
    function getRoundData(uint80 _roundId_)external view override returns(
        uint80,
        int256,
        uint256,
        uint256,
        uint80
    ){
        return (_roundId, _rainfall(), _timestamp, _timestamp, _roundId_);
    }
    function latestRoundData()external view override returns(
        uint80,
        int256,
        uint256,
        uint256,
        uint80
    ){
        return (_roundId, _rainfall(), _timestamp, _timestamp, _roundId);
    }
    function _rainfall() public view returns (int256){
        uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender)))%1000;
        return int256(pseudoRandom) ;
    }
    function _updateData() private {
        _roundId++;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }
    function updateData() external{
        _updateData();
    }

}