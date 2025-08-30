// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CropInsurance is Ownable {
    AggregatorV3Interface private weatherOracle;
    AggregatorV3Interface private ethUsdPriceFeed;

    uint public constant RAINFALL_THRESHOLD = 500;
    uint public constant INSURANCE_PREMIUM_USD = 10;
    uint public constant INSURANCE_PAYOUT_USD = 50;

    mapping(address => bool) public hasInsurance;
    mapping(address => uint256) public lastClaimTimestamp;

    event InsurancePurchased(address indexed farmer, uint amount);
    event ClaimSubmitted(address indexed farmer);
    event ClaimPaid(address indexed farmer, uint256 amount);
    event RainfallChecked(address indexed farmer, uint rainfall);

    constructor(address _weatherOracle, address _ethUsdPriceFeed) payable Ownable(msg.sender) {
        weatherOracle = AggregatorV3Interface(_weatherOracle);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    }

    function getEthPrice() public view returns(uint){
        (
            ,
            int256 price,
            ,
            ,
        ) = ethUsdPriceFeed.latestRoundData();
        return uint(price);
    }

    function purchasePremium() external  payable {
        uint ethPrice = getEthPrice();
        uint premInEth = (INSURANCE_PREMIUM_USD * 1e18) /ethPrice;

        require(msg.value >= premInEth, "insufficient funds");
        require(!hasInsurance[msg.sender], "already purchased");

        hasInsurance[msg.sender] = true;
        emit InsurancePurchased(msg.sender, msg.value);
    }

    function checkRainfallAndClaim() external {
        require(hasInsurance[msg.sender], "not purchased");
        require(block.timestamp >= lastClaimTimestamp[msg.sender] + 1 days, "must waut 24hr between claims");
        (uint80 roundId, int256 rainfall,, uint256 updatedAt, uint80 answeredInRound) = weatherOracle.latestRoundData();

        require(updatedAt > 0, "round not complete");
        require(answeredInRound > roundId, "stale data");
        
        uint256 currentRainfall = uint256(rainfall);
        emit RainfallChecked(msg.sender, currentRainfall);

        if(currentRainfall < RAINFALL_THRESHOLD){
            lastClaimTimestamp[msg.sender] = block.timestamp;
            emit ClaimSubmitted(msg.sender);
        }

        uint256 ethPrice = getEthPrice();
        uint payOutInEth = (INSURANCE_PAYOUT_USD * 1e18) /ethPrice;

        (bool success, ) = msg.sender.call{value:payOutInEth}("");

        require(success, "transaction failed");
        emit ClaimPaid(msg.sender, payOutInEth);
    }
    
    function getCurrentRaindfall() public view returns(uint){
        (
            ,
            int256 price,
            ,
            ,
        ) = weatherOracle.latestRoundData();
        return uint(price);
    }

    function withdraw() external onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

}