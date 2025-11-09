//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

// Smart contracts can not access the outside world on their own.
// Oracle is a trusted delivery who brings real-world data into the blockchain.
// chainlink:https://chain.link ;chainlink is the gold standard for decentralized oracles.
// Chainlink offers APIs for price feeds,weather,randomness and even entire data networks that are secure,tamper-proof and widelyused by DEFi projects.
// Chainlink has standard interfaces like "AggregatorV3Interface" that let us easily integrate their data feeds into our samrt contracts.

// This contract is a simulated chainlink-style oracle that randomly generates rainfall value.

// This is chainlink's standard oracle interface--used to fetch data like price feeds or, in our case, mock rainfall.
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// Give ownership functionality--- including an "owner()" and the "onlyOwner" modifier. It can give the deployer admin access.
import "@openzeppelin/contracts/access/Ownable.sol";

// When the contract inherits from "AggreatorV3Interface", it means that it must implement functions like "latestRoundData()".
contract MockWeatherOracle is AggregatorV3Interface,Ownable{
    uint8 private _decimals; // Define the precision of data
    string private _description;// A text label of the feed.
    uint80 private _roundId;// Data update cycles.
    uint256 private _timestamp;// Records when the last update occurred.
    uint256 private _lastUpdateBlock;// Tracks the block when the last update happened, used to add randomness.

    constructor() Ownable(msg.sender){
        _decimals=0;
        _description="MOCK/RAINFALL/USD";
        _roundId=1;
        _timestamp=block.timestamp;
        _lastUpdateBlock=block.number;

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

    // It mimics chainlink's standard function for accessing historical data.
    // It would return the round ID, a mock rainfall value, the same timestamp twice and same round ID for "answerInRound".
    function getRoundData(uint80 _roundId_) external view override returns(uint80 roundId,int256 answer,uint256 startedAt,uint256 updatedAt,uint80 answeredInRound){
        return(_roundId_,_rainfall(),_timestamp,_timestamp,_roundId_);
    }

    // This is the most important function---apps use it to get the latest data.
    // It would return current round ID, random rainfall value, timestamps and round ID confirmation.
    // This function is what the "CropInsurance" contarct will call to get current rainfall.
    function latestRoundData() external view override returns(uint80 roundId,int256 answer,uint256 startedAt,uint256 updatedAt,uint80 answeredInRound){
        return(_roundId,_rainfall(),_timestamp,_timestamp,_roundId);
    }

    // Function to get current rainfall with random variation
    // Every oracle data updates, it is necessary for miners to generate new blocks and storage the information in blocks.
    // "view" and "pure" functions don't generate new blocks."public" and "external" functions generate new blocks.
    function _rainfall() public view returns(int256){
        // Use block information to generate pseudo-random variation
        // Compute how many blocks have passed since the last oracle update
        uint256 blockSinceLastUpdate=block.number-_lastUpdateBlock; // Calculate how many blocks have passed since last update.
        // Here apply hash functions to pack and hash three variables to generate random value.
        // block.timestamp: current time
        // block.coinbase: address of the miner
        // abi.encodePacked(...):Pack multiple values into a tight byte array (no padding)
        // keccak256(...)Hash function: produces 256-bit output from input
        // %1000: the result is converted to an integer between 0-999 using "%1000"
        uint256 randomFactor=uint256(keccak256(abi.encodePacked(block.timestamp,block.coinbase,blockSinceLastUpdate)))%1000;

        return int256(randomFactor);

    }

    // Function to update random rainfall
    // Increase the round and record when the new data was created.
    function _updateRandomRainfall() private{
        _roundId++;
        _timestamp=block.timestamp;
        _lastUpdateBlock=block.number;
    }

    // Function to force update rainfall(anyone can call)
    // This is the public funciton anyone can call to update the "oracle" data.
    function updateRandomRainfall() external{
        _updateRandomRainfall();
    }

}
