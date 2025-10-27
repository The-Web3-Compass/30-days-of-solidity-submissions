
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
购买保险（purchaseInsurance） —— 付 ETH 作为保险费。

自动理赔（checkRainfallAndClaim） —— 如果“降雨量”太少（即干旱），就自动赔款。

由 Chainlink Oracle 提供天气和 ETH/USD 数据 —— 保证数据可信。
*/

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CropInsurance is Ownable {
    uint256 public constant RAINFALL_THRESHOLD = 500;   //降雨量閥值
    uint256 public constant INSURANCE_PREMIUM_USD = 10; //保险费
    uint256 public constant INSURANCE_PAYOUT_USD = 50;  //理赔金额

    AggregatorV3Interface private weatherOracle;
    AggregatorV3Interface private ethUsdPriceFeed;

    constructor(address _weatherOracle, address _ethUsdPriceFeed) payable Ownable(msg.sender){
        weatherOracle = AggregatorV3Interface(_weatherOracle);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    }

    mapping(address => bool) public hasInsurance;   //是否已经购买保险，有资格
    mapping(address => uint256) public lastTimeClaim;   //Last time

    event InsurancePurchased(address indexed farmer, uint256 amount);
    event ClaimSubmitted(address indexed farmer);
    event ClaimPaid(address indexed farmer, uint256 amount);
    event RainfallChecked(address indexed farmer, uint256 rainfall);

    //购买保险
    function purchaseInsurance() external payable{
        uint256 ethPrice = getEthPrice();
        uint256 premiumInEth = (INSURANCE_PREMIUM_USD * 1e18) / ethPrice;

        require(msg.value >= premiumInEth, "insufficient premium amount");
        require(!hasInsurance[msg.sender],"already bought");

        hasInsurance[msg.sender] = true;
        emit InsurancePurchased(msg.sender, msg.value);
    }

    function getEthPrice()internal view returns(uint256){
        (,int256 price, , ,) = ethUsdPriceFeed.latestRoundData();
        return uint256(price);
    }

    function checkRainfallAndClaim() external{
        require(hasInsurance[msg.sender],"Not bought");
        require(block.timestamp >= lastTimeClaim[msg.sender] + 7 days,"must 7 days");

        (
            uint80 roundId,
            int256 rainfall,
            ,
            uint256 updateAt,
            uint80 answerInRound
        ) = weatherOracle.latestRoundData();

        require(updateAt > 0, "Round not complete");
        require(answerInRound >= roundId,"stale data");

        uint256 currentRainfall = uint256(rainfall);
        emit RainfallChecked(msg.sender, currentRainfall);

        if(currentRainfall < RAINFALL_THRESHOLD){
            lastTimeClaim[msg.sender] = block.timestamp;
            emit ClaimSubmitted(msg.sender);

            uint256 ethPrice = getEthPrice();
            uint256 amountToSend = INSURANCE_PAYOUT_USD * 1e18 / ethPrice;

            (bool success,) = msg.sender.call{value: amountToSend}("");
            require(success,"tx failed");

            emit ClaimPaid(msg.sender, amountToSend);
        }
    }

    function getCurrentRainfall() public view returns (uint256) {
        (
            ,
            int256 rainfall,
            ,
            ,
        ) = weatherOracle.latestRoundData();
        return uint256(rainfall);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

}

