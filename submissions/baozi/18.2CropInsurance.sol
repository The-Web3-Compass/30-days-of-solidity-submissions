// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CropInsurance
/// @notice A simple parametric insurance contract based on rainfall levels
contract CropInsurance is Ownable {
    AggregatorV3Interface private immutable weatherOracle;
    AggregatorV3Interface private immutable ethUsdPriceFeed;

    uint256 public constant RAINFALL_THRESHOLD = 500; // mm
    uint256 public constant INSURANCE_PREMIUM_USD = 10; // USD
    uint256 public constant INSURANCE_PAYOUT_USD = 50;  // USD

    mapping(address => bool) public hasInsurance;
    mapping(address => uint256) public lastClaimTimestamp;

    event InsurancePurchased(address indexed farmer, uint256 ethAmount);
    event ClaimSubmitted(address indexed farmer);
    event ClaimPaid(address indexed farmer, uint256 payoutEth);
    event RainfallChecked(address indexed farmer, uint256 rainfallMm);

    constructor(address _weatherOracle, address _ethUsdPriceFeed) payable Ownable(msg.sender) {
        require(_weatherOracle != address(0) && _ethUsdPriceFeed != address(0), "Invalid oracle addresses");
        weatherOracle = AggregatorV3Interface(_weatherOracle);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    }

    /// @notice Allows users to purchase insurance by paying ETH equivalent to $10
    function purchaseInsurance() external payable {
        require(!hasInsurance[msg.sender], "Already insured");

        uint256 premiumInEth = (INSURANCE_PREMIUM_USD * 1e18) / getEthPrice();
        require(msg.value >= premiumInEth, "Insufficient premium payment");

        hasInsurance[msg.sender] = true;
        emit InsurancePurchased(msg.sender, msg.value);
    }

    /// @notice Checks rainfall and pays out if conditions are met (less than 500mm in latest data)
    function checkRainfallAndClaim() external {
        require(hasInsurance[msg.sender], "No active insurance");
        require(block.timestamp >= lastClaimTimestamp[msg.sender] + 1 days, "Claim cooldown: 24h");

        (
            uint80 roundId,
            int256 rainfall,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = weatherOracle.latestRoundData();

        require(updatedAt > 0, "No weather data available");
        require(answeredInRound >= roundId, "Stale weather data");

        uint256 currentRainfall = uint256(rainfall);
        emit RainfallChecked(msg.sender, currentRainfall);

        if (currentRainfall < RAINFALL_THRESHOLD) {
            lastClaimTimestamp[msg.sender] = block.timestamp;
            emit ClaimSubmitted(msg.sender);

            uint256 payoutInEth = (INSURANCE_PAYOUT_USD * 1e18) / getEthPrice();

            (bool success, ) = payable(msg.sender).call{value: payoutInEth}("");
            require(success, "ETH transfer failed");

            emit ClaimPaid(msg.sender, payoutInEth);
        }
    }

    /// @notice Fetches current ETH price from Chainlink
    function getEthPrice() public view returns (uint256) {
        (, int256 price, , ,) = ethUsdPriceFeed.latestRoundData();
        require(price > 0, "Invalid ETH price");
        return uint256(price);
    }

    /// @notice Returns current rainfall reported by oracle
    function getCurrentRainfall() public view returns (uint256) {
        (, int256 rainfall, , ,) = weatherOracle.latestRoundData();
        return uint256(rainfall);
    }

    /// @notice Owner can withdraw contract balance
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Fallback to accept plain ETH transfers
    receive() external payable {}

    /// @notice Check contract's current ETH balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
