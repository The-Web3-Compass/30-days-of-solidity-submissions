// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title WeatherOracle
 * @dev Build a smart contract that retrieves live weather data using an oracle like Chainlink.
 * You'll create a decentralized crop insurance contract where farmers can claim insurance
 * if rainfall drops below a certain threshold during the growing season.
 * Since the Ethereum blockchain can't access real-world data on its own,
 * you'll use an oracle to fetch off-chain weather information and trigger payouts automatically.
 * This project demonstrates how to securely integrate external data into your contract logic and
 * highlights the power of real-world connectivity in smart contracts.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 18
 */
abstract contract WeatherOracle is Ownable, AggregatorV3Interface {
    constructor() Ownable(msg.sender) {}

    function decimals() external pure returns (uint8) {
        return 0;
    }

    function description() external pure returns (string memory) {
        return "MOCK_RAIN_MM";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function getRoundData(
        uint80 _roundId
    )
        public pure
        returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        int256 prng100 = int256(uint256(keccak256(abi.encodePacked(_roundId, "rain"))) % 100);

        return (_roundId, prng100, uint256(_roundId), uint256(_roundId), _roundId);
    }

    function latestRoundData()
        public view
        returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return getRoundData(uint80(block.timestamp));
    }
}
