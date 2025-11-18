// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IAggregatorV3.sol";

contract OracleManager {
    mapping(address => address) public aggregators; // token => aggregator

    function setAggregator(address token, address aggregator) external {
        aggregators[token] = aggregator;
    }

    /// @dev returns price with 8 decimals (Chainlink style) and updatedAt
    function getPrice(address token) public view returns (int256 price, uint256 updatedAt) {
        address agg = aggregators[token];
        require(agg != address(0), "no aggregator");
        (, int256 answer, , uint256 uAt, ) = IAggregatorV3(agg).latestRoundData();
        return (answer, uAt);
    }
}