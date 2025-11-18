//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

// This contract can let farmers pay a premium(in ETH),monitors the rainfall and automatically pays out if rainfall is too low.
// This contract simulates a blockchain-based crop insurance program. Farmers can pay a samll premium, and if the rainfall is below a threshold, they're automatically paid out---no middlemen,no waiting.

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CropInsurance is Ownable{
    AggregatorV3Interface private weatherOracle;
    AggregatorV3Interface private ethUsdPriceFeed;

    uint256 public constant RAINFALL_THRESHOLD=500;
    uint256 public constant INSURANCE_PREMIUM_USD=10;
    uint256 public constant INSURANCE_PAYOUT_USD=50;

    mapping(address=>bool) public hasInsurance;
    mapping(address=>uint256) public lastClaimTimestamp;

    event InsurancePurchased(address indexed farmer,uint256 amount);
    event ClaimSubmitted(address indexed farmer);
    event ClaimPaid(address indexed farmer,uint256 amount);
    event RainfallChecked(address indexed farmer,uint256 rainfall);

    // address _weatherOracle: address of rainfall oracle(like the mock we built earlier)
    // address _ethUsdPriceFeed: address of a chainlink price feed that gives us ETH=>USD conversion.
    // "Ownable(msg.sender)":initializes the contract owner as the person who deployed it.
    constructor(address _weatherOracle, address _ethUsdPriceFeed) payable Ownable(msg.sender){
        weatherOracle=AggregatorV3Interface(_weatherOracle);
        ethUsdPriceFeed=AggregatorV3Interface(_ethUsdPriceFeed);
    }

    // "external payable": this function can receive ETH directly from the user
    function purchaseInsurance() external payable{
        uint256 ethPrice= getEthPrice();// fetch the current price of ETH inUSD using chainlink
        uint256 premiumInEth=(INSURANCE_PREMIUM_USD*1e18)/ethPrice;

        require(msg.value>=premiumInEth,"Insufficient premium amount");
        require(!hasInsurance[msg.sender],"Already insured");
        
        hasInsurance[msg.sender]=true;
        emit InsurancePurchased(msg.sender,msg.value);

    }

    function checkRainfallAndClaim() external {
        require(hasInsurance[msg.sender],"No active insurance");
        // Enforce a 1-day cooldown between claims to avoid spamming.
        require(block.timestamp>=lastClaimTimestamp[msg.sender]+1 days,"Must wait 24h between claims");

        // Pulls latest rainfall data from the weather oracle.
        (uint80 roundId,int256 rainfall, ,uint256 updatedAt,uint80 answeredInRound)=weatherOracle.latestRoundData();

        require(updatedAt>0,"Round not complete");
        require(answeredInRound>=roundId,"Stale data");

        uint256 currentRainfall=uint256(rainfall);
        emit RainfallChecked(msg.sender,currentRainfall);

        // If rainfall is below the drought threshold, the claim proces continues.
        if (currentRainfall<RAINFALL_THRESHOLD){
            lastClaimTimestamp[msg.sender]=block.timestamp;
            emit ClaimSubmitted(msg.sender);
            
            // Transfer ETH to the farmer
            uint256 ethPrice=getEthPrice();
            uint256 payoutInEth=(INSURANCE_PAYOUT_USD*1e18)/ethPrice;

            (bool success,)=msg.sender.call{value:payoutInEth}("");
            require(success,"Transfer failed");

            emit ClaimPaid(msg.sender,payoutInEth);
        }

    }

    // This function talks to chainlink which gives us the latest ETH price in USD.
    function getEthPrice() public view returns(uint256){
        (,int256 price,,,)=ethUsdPriceFeed.latestRoundData();
        return uint256(price);
    }
    
    // This function lets anyone view current rainfall.
    function getCurrentRainfall() public view returns(uint256){
        (,int256 rainfall,,,)=weatherOracle.latestRoundData();
        return uint256(rainfall);

    }

    function withdraw() external onlyOwner{
        payable(owner()).transfer(address(this).balance);

    }

    // This function allows the contract to receive ETH without calling a function.
    receive() external payable{}

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }
}

