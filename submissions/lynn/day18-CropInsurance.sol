//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import "./day18-AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CropInsurance is Ownable {
    AggregatorV3Interface private weatherOracle;
    AggregatorV3Interface private ethUsdPrice;

    uint256 public constant RAINFALL_THRESHOLD = 500;
    uint256 public constant INSURANCE_PRICE_USD = 10;
    uint256 public constant INSURANCE_PAYOUT_USD = 50;

    mapping(address => bool) public hasInsurance;
    mapping(address => uint256) public lastClaimTime;

    event InsurancePurchased(address indexed user, uint256 price);
    event ClaimSubmitted(address indexed user);
    event ClaimPaid(address indexed user, uint256 payAmount);
    event WeatherChecked(address indexed user, uint256 rainfall);

    constructor(address _weatherOracle, address _ethUsdPrice) Ownable(msg.sender) {
        weatherOracle = AggregatorV3Interface(_weatherOracle);
        ethUsdPrice = AggregatorV3Interface(_ethUsdPrice);
    }

    function purchaseInsurance() external payable {
        require(!hasInsurance[msg.sender], "You already have insurance");

        uint256 ethPrice = getEthPrice();
        uint256 insurancePriceEth = INSURANCE_PRICE_USD * 1e18 / ethPrice;
        require(msg.value >= insurancePriceEth, "Insufficient amount");

        hasInsurance[msg.sender] = true;
        emit InsurancePurchased(msg.sender, insurancePriceEth);
    }

    function checkRainfallAndClaim() external {
        require(hasInsurance[msg.sender], "No active insurance");
        require(block.timestamp >= lastClaimTime[msg.sender] + 1 days, "Must wait 1 day between claims");

        // get rainfall data
        (uint256 roundId,
         int256 rainfall,
         ,
         uint256 updateTime,
         uint256 answerRoundId
        ) = weatherOracle.latestRoundData();
        require(updateTime > 0, "Round not complete");
        require(answerRoundId >= roundId, "Stale data");

        uint256 currentRainfall = uint256(rainfall);
        emit WeatherChecked(msg.sender, currentRainfall);

        if (currentRainfall < RAINFALL_THRESHOLD) {
            // submit insurance claim
            lastClaimTime[msg.sender] = block.timestamp;
            emit ClaimSubmitted(msg.sender);
            
            // calculate payout in eth
            uint256 ethPrice = getEthPrice();
            uint256 insurancePayoutEth = INSURANCE_PAYOUT_USD * 1e18 / ethPrice;
            (bool success, ) = msg.sender.call{value: insurancePayoutEth}("");
            require(success, "Insurance payout failed");

            emit ClaimPaid(msg.sender, insurancePayoutEth);
        }
    }

    function getEthPrice() public view returns(uint256) {
        (
            ,
            int256 price,
            ,
            ,
        ) = ethUsdPrice.latestRoundData();
        return uint256(price);
    }

    function getCurrentRainfall() public view returns(uint256) {
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

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }
 
 }