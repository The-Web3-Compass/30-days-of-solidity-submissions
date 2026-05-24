// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import {
    AggregatorV3Interface
} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract conversionRates {
    AggregatorV3Interface internal ETHpriceFeed;
    AggregatorV3Interface internal BTCpriceFeed;

    constructor() {
        // ETH/USD price feed
        ETHpriceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        BTCpriceFeed = AggregatorV3Interface(
            0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
        );
    }

    function getEthLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = ETHpriceFeed.latestRoundData();
        return uint256(price); // Price in USD with 8 decimals
    }

    function getBtcLatestPrice() public view returns (uint256) {
        //priceFeed = AggregatorV3Interface(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43)
        (, int256 price, , , ) = BTCpriceFeed.latestRoundData();
        return uint256(price); // Price in USD with 8 decimals
    }

    function convertToEth(uint256 _usdAmount) public view returns (uint256) {
        uint256 ethPrice = getEthLatestPrice(); // e.g., 200000000000 ($2,000)
        return (_usdAmount * 1e18) / ethPrice;
    }

    function convertToBTC(uint256 _usdAmount) public view returns (uint256) {
        uint256 btcPrice = getBtcLatestPrice();
        uint256 usdValue = (_usdAmount * uint256(btcPrice)) / 1e8;
        return usdValue;
    }
}
