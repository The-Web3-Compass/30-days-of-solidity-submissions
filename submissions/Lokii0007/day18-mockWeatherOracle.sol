// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockWeatherOracle is AggregatorV3Interface, Ownable {
    uint8 private _decimals;
    string public _description;
    uint80 private _roundId;
    uint256 private timestamp;
    uint256 private lastUpdatedBlock;

    constructor() Ownable(msg.sender) {
        _decimals = 0;
        _description = "MOCK/RAINFALL/USD";
        _roundId = 1;
        timestamp = block.timestamp;
        lastUpdatedBlock = block.number;
    }

    function rainfall() public view returns(int256){
        uint blockSinceLastUpdate = block.number - lastUpdatedBlock;
        uint randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, blockSinceLastUpdate))) % 1000;

        return int256(randomFactor);
    }

    function updateRandomRainfall() private {
        _roundId ++;
        timestamp = block.timestamp;
        lastUpdatedBlock = block.number;
    }

    function getRoundData(uint80 _roundId_) external view override returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound ){
        return(_roundId_, rainfall(), timestamp, timestamp, _roundId);
    }

    function latestRoundData() external view override returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound ){
        return(_roundId, rainfall(), timestamp, timestamp, _roundId);
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