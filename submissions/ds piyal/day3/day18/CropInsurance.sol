// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CropInsurance is Ownable {
    AggregatorV3Interface private weatherOracle;
    AggregatorV3Interface private ethUsdPriceFeed;

    uint256 public constant RAINFALL_THRESHOLD = 500;
    uint256 public constant INSURANCE_PREMIUM_USD = 10;
    uint256 public constant INSURANCE_PAYOUT_USD = 50;
    uint256 public constant MAX_DATA_STALENESS = 3600;

    mapping (address => bool) public hasInsurance;
    mapping (address => uint256) public lastClaimTimestamp;
    
    mapping (address => bool) private _claiming;

    event InsurancePurchased(address indexed farmer,uint256 amount);
    event ClaimSubmitted(address indexed farmer);
    event ClaimPaid(address indexed farmer,uint256 amount);
    event RainfallChecked(address indexed farmer, uint256 rainfall);

    constructor(address _weatherOracle,address _ethUsdPriceFeed) payable Ownable(msg.sender) {
        weatherOracle = AggregatorV3Interface(_weatherOracle);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    }
    
    function purchaseInsurance() external payable {
        uint256 ethPrice = getEthPrice();
        uint256 premiumInEth = (INSURANCE_PREMIUM_USD * 1e18) / ethPrice;

        require(msg.value >= premiumInEth,"Insufficient premium amount");
        require(!hasInsurance[msg.sender],"Already Insured");

        hasInsurance[msg.sender] = true;
        emit InsurancePurchased(msg.sender,msg.value);
    }
    
    function checkRainfallAndClaim() external {
        require(hasInsurance[msg.sender],"No Insurance");
        require(block.timestamp >= lastClaimTimestamp[msg.sender] + 1 days,"Must wait 24h between claims"); // Fixed typo
        require(!_claiming[msg.sender], "Already claiming");
        
        _claiming[msg.sender] = true;
        
        (
            uint80 roundId,
            int256 rainfall,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = weatherOracle.latestRoundData();

        require(updatedAt > 0,"Round not complete");
        require(answeredInRound >= roundId,"Stale data");
        require(block.timestamp - updatedAt <= MAX_DATA_STALENESS, "Oracle data too old");

        uint256 currentRainfall = uint256(rainfall);
        emit RainfallChecked(msg.sender, currentRainfall);

        if (currentRainfall < RAINFALL_THRESHOLD) {
            lastClaimTimestamp[msg.sender] = block.timestamp;
            emit ClaimSubmitted(msg.sender);

            uint256 ethPrice = getEthPrice();
            uint256 payoutInEth = (INSURANCE_PAYOUT_USD * 1e18) / ethPrice;
            
            require(address(this).balance >= payoutInEth, "Insufficient contract balance");

            (bool success, ) = msg.sender.call{value: payoutInEth}("");
            require(success, "Transfer failed");

            emit ClaimPaid(msg.sender,payoutInEth);
        }
        
        _claiming[msg.sender] = false;
    }

    function getEthPrice() public view returns(uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        require(price > 0, "Invalid ETH price");
        return uint256(price) * 1e10;
    }

    function getCurrentRainfall() public view returns (uint256) {
        (, int256 rainfall, , , ) = weatherOracle.latestRoundData();
        return uint256(rainfall);
    }

    function withdraw() external onlyOwner {
        payable (owner()).transfer(address(this).balance);
    }

    receive() external payable { }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
}