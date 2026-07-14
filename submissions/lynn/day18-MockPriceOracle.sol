//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import "./day18-AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockPriceOracle is Ownable, AggregatorV3Interface {
    //前面加_的参数名和函数名为当前合约自己的，区别与继承的
    uint8 private _decimals;
    string private _description;
    uint8 private _roundId;
    uint256 private _timestamp;
    uint256 private _lastUpdateBlock;

    constructor() Ownable(msg.sender) {
        _decimals = 0;
        _description = "MOCK/ETHUSDPRICE";
        _roundId = 0;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }

    function decimals() external view override returns(uint8) {
        return _decimals;
    }

    function description() external view override returns(string memory) {
        return _description;
    }

    function version() external pure override returns(uint256) {
        return 1;
    }

    function getRoundData(uint8 _roundId_) external view override returns(
        uint8 roundId, int256 answer,
        uint256 startedAt, uint256 updatedAt,
        uint8 answeredInRound
    ) {
        return (_roundId_, _ethUsdPrice(), _timestamp, _timestamp, _roundId_);
    }

    function latestRoundData() external view override returns(
        uint8 roundId, int256 answer, 
        uint256 startedAt, uint256 updatedAt,
        uint8 answeredInRound
    ) {
        return (_roundId, _ethUsdPrice(), _timestamp, _timestamp, _roundId);
    }

    function _ethUsdPrice() public pure returns(int256) {
        return 2540;
    }
}