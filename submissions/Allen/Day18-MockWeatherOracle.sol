// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockWeatherOracleis AggregatorV3Interface,Ownable{
    /**
    Inherits from AggregatorV3Interface — 
    meaning it must implement functions like latestRoundData().
    */

    uint8 private _decimals;
    string private _description;
    uint80 private _roundId;
    uint256 private _timestamp;
    uint256 private _lastUpdateBlock;

    constructor() Ownable(msg.sender) {
        _decimals = 0;
        _description = "MOCK/RAINFALL/USD";
        _roundId = 1;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }

    function latestRoundData() external view override
        returns (uint80 roundId, int256 answer, uint256 startedAt, 
        uint256 updatedAt, uint80 answeredInRound){

        return (_roundId, _rainfall(), _timestamp, _timestamp, _roundId);
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

    function getRoundData(uint80 _roundId_) external view override
        returns (uint80 roundId, int256 answer, uint256 startedAt, 
        uint256 updatedAt, uint80 answeredInRound){

        return (_roundId_, _rainfall(), _timestamp, _timestamp, _roundId_);
    }

    // Function to get current rainfall with random variation
    function _rainfall() public view returns (int256) {
        // Use block information to generate pseudo-random variation
        uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;
        // Random number between 0 and 999
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.coinbase,
            blocksSinceLastUpdate
        ))) % 1000; 

        // Return random rainfall between 0 and 999mm
        return int256(randomFactor);
    }

    // Function to update random rainfall
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