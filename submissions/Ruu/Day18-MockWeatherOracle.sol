//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockWeatherOracle is AggregatorV3Interface, Ownable{

    uint8 private _decimals;
    string private _description;
    uint80 private _roundId;
    uint256 private _timestamp;
    uint256 private _LastUpdateBlock;

    constructor() Ownable(msg.sender){

        _decimals = 0;
        _description = "MOCK/RAINFALL/USD";
        _roundId = 1;
        _timestamp = block.timestamp;
        _LastUpdateBlock = block.number;
    }

    function _rainfall() public view returns(int256){
        uint256 BlockSinceLastUpdate = block.number - _LastUpdateBlock;
        uint256 RandomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.coinbase, BlockSinceLastUpdate)))%1000;
        return int256(RandomFactor);
    }

    function _UpdateRandomRainfall() private{
        _roundId++;
        _timestamp = block.timestamp;
        _LastUpdateBlock = block.number;
    }

    function UpdateRandomRainfall() external{
        _UpdateRandomRainfall();
    }

    function getRoundData(uint80 _roundId_) external view override returns(uint80 roundId, int256 answer, uint256 StartedAt, uint256 UpdatedAt, uint80 AnsweredInRound){
        return(_roundId_, _rainfall(), _timestamp, _timestamp, _roundId);
    }

    function latestRoundData() external view override returns(uint80 roundId, int256 answer, uint256 StartedAt, uint256 UpdatedAt, uint80 AnsweredInRound){
        return(_roundId, _rainfall(), _timestamp, _timestamp, _roundId);
    }

    function decimals() external view override returns(uint8){
        return _decimals;
    }

    function description() external view override returns(string memory){
        return _description;
    }

    function version() external pure override returns(uint256){
        return 1;
    }
}
