// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
contract TipJar {
    AggregatorV3Interface internal ethUsd;
    AggregatorV3Interface internal ethEur;

    uint256 public usdBalance;
    uint256 public eurBalance;

    constructor (address _ethUsdPriceFeedAddress, _address _ethUsdPriceFeedAddress) public {
        ethUsd = AggregatorV3Interface(_ethUsdPriceFeedAddress);
        ethEur = AggregatorV3Interface(_ethEurPriceFeedAddress);
    }

    function getEthUsdPrice() public view returns (int) {
        (, int price, , , ) = ethUsd.latestRoundData();
        return price;
    }

    function getEthEurPrice() public view returns (int) {
        (, int price, , , ) = ethEur.latestRoundData();
        return price;
    }

    function tipInUsd (uint256 amountInUsd) public payable {
        require(msg.value > 0, "Tip amount must be greater than zero");
        int ethUsdPrice = getEthUsdPrice();
        uint256 amountInEth = (amountInUsd * 1e18) / uint256(ethUsdPrice);
        ethUsd += amountInEth;
    }

    function tipInEur (uint256 amountInEur) public payable {
        require(msg.value > 0, "Tip amount must be greater than zero");
        int ethEurPrice = getEthEurPrice();
        uint256 amountInEth = (amountInEur * 1e18) / uint256(ethEurPrice);
        ethEur += amountInEth;
    }
}
