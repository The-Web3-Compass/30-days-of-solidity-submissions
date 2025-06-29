//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CropInsurance is Ownable{

    AggregatorV3Interface private WeatherOracle;
    AggregatorV3Interface private EthUsdPriceFeed;

    uint256 public constant RAINFALL_THRESHOLD = 500;
    uint256 public constant INSURANCE_PREMIUM_USD = 10;
    uint256 public constant INSURANCE_PAYOUT_USD = 50;

    mapping(address => bool) public hasInsurance;
    mapping(address => uint256) public lastClaimTimestamp;

    event InsurancePurchase(address indexed farmer, uint256 amount);
    event ClaimSubmitted(address indexed farmer);
    event ClaimPaid(address indexed farmer, uint256 amount);
    event RainfallChecked(address indexed farmer, uint256 fainfall);

    constructor(address _WeatherOracle, address _EthUsdPriceFeed) Ownable(msg.sender) {
        WeatherOracle = AggregatorV3Interface(_WeatherOracle);
        EthUsdPriceFeed = AggregatorV3Interface(_EthUsdPriceFeed);
    }

    function PurchaseInsurance() external payable{
        uint256 EthPrice = getEthPrice();
        uint256 PremiumInEth = (INSURANCE_PREMIUM_USD * 1e18)/EthPrice;

        require(msg.value >= PremiumInEth, "Insufficient amount");
        require(!hasInsurance[msg.sender], "Already insured");

        hasInsurance[msg.sender] = true;
        emit InsurancePurchase(msg.sender, msg.value);
    }

    function CheckRainfallAndClaim() external{
        require(hasInsurance[msg.sender], "No active insurance");
        require(block.timestamp >= lastClaimTimestamp[msg.sender] + 1 days, "Must wait 24h between claims");
        (uint80 roundId, int256 rainfall, , uint256 UpdatedAt, uint80 AnsweredInRound) = WeatherOracle.latestRoundData();
        require(UpdatedAt > 0, "Round not complete");
        require(AnsweredInRound >= roundId, "Stale data");

        uint256 CurrentRainfall = uint256(rainfall);
        emit RainfallChecked(msg.sender, CurrentRainfall);

        if(CurrentRainfall < RAINFALL_THRESHOLD){
            lastClaimTimestamp[msg.sender] = block.timestamp;
            emit ClaimSubmitted(msg.sender);
        }

        uint256 EthPrice = getEthPrice();
        uint256 PayoutInEth = (INSURANCE_PAYOUT_USD * 1e18)/EthPrice;
        (bool success, ) = msg.sender.call{value:PayoutInEth}("");
        require(success, "Transfer failed");
        emit ClaimPaid(msg.sender, PayoutInEth);
    }

    function getEthPrice() public view returns(uint256){
        ( , int256 price, , , ) = EthUsdPriceFeed.latestRoundData();
        return uint256(price);
    }

    function getCurrentRainfall() public view returns(uint256){
        ( , int256 rainfall, , ,) = WeatherOracle.latestRoundData();
        return uint256(rainfall);
    }

    function Withdraw() external onlyOwner {
        payable (owner()).transfer(address(this).balance);
    }

    receive() external payable{}

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

}
