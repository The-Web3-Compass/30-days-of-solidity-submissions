//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

interface AggregatorV3Interface {
    function decimals() external view returns(uint8);

    function description() external view returns(string memory);

    function version() external pure returns(uint256);

    function getRoundData(uint8 _roundId_) external view returns(
        uint8 roundId, int256 answer,
        uint256 startedAt, uint256 updatedAt,
        uint8 answeredInRound
    );

    function latestRoundData() external view returns(
        uint8 roundId, int256 answer, 
        uint256 startedAt, uint256 updatedAt,
        uint8 answeredInRound
    );
}