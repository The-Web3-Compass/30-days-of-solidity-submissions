// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CropInsurance is Ownable {
    AggregatorV3Interface private weatherOracle;
    AggregatorV3Interface private ethUsdPriceFeed;

    uint256 public constant RAINFALL_THRESHOLD = 500; // mm
    uint256 public constant INSURANCE_PREMIUM_USD = 10;
    uint256 public constant INSURANCE_PAYOUT_USD = 50;

    mapping(address => bool) public hasInsurance;
    mapping(address => uint256) public lastClaimTimestamp;

    event InsurancePurchased(address indexed farmer, uint256 amount);
    event ClaimSubmitted(address indexed farmer);
    event ClaimPaid(address indexed farmer, uint256 amount);
    event RainfallChecked(address indexed farmer, uint256 rainfall);

    constructor(address _weatherOracle, address _ethUsdPriceFeed) payable Ownable(msg.sender) {
        weatherOracle = AggregatorV3Interface(_weatherOracle);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    }

    /// @notice Allows a user to purchase rainfall insurance by paying the ETH equivalent of $10
    function purchaseInsurance() external payable {
        require(!hasInsurance[msg.sender], "Already insured");

        uint256 premiumInEth = usdToEth(INSURANCE_PREMIUM_USD);
        require(msg.value >= premiumInEth, "Insufficient premium amount");

        hasInsurance[msg.sender] = true;

        // Refund any extra ETH sent
        if (msg.value > premiumInEth) {
            payable(msg.sender).transfer(msg.value - premiumInEth);
        }

        emit InsurancePurchased(msg.sender, premiumInEth);
    }

    /// @notice Farmers can submit a claim if rainfall is below threshold and 24h has passed
    function checkRainfallAndClaim() external {
        require(hasInsurance[msg.sender], "No active insurance");
        require(block.timestamp >= lastClaimTimestamp[msg.sender] + 1 days, "Must wait 24h between claims");

        (
            uint80 roundId,
            int256 rainfall,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = weatherOracle.latestRoundData();

        require(updatedAt > 0, "Round not complete");
        require(answeredInRound >= roundId, "Stale data");

        uint256 currentRainfall = uint256(rainfall);
        emit RainfallChecked(msg.sender, currentRainfall);

        if (currentRainfall < RAINFALL_THRESHOLD) {
            lastClaimTimestamp[msg.sender] = block.timestamp;
            emit ClaimSubmitted(msg.sender);

            uint256 payoutInEth = usdToEth(INSURANCE_PAYOUT_USD);

            // Send ETH payout
            (bool success, ) = payable(msg.sender).call{value: payoutInEth}("");
            require(success, "Transfer failed");

            emit ClaimPaid(msg.sender, payoutInEth);

            // Invalidate insurance after successful claim
            hasInsurance[msg.sender] = false;
        }
    }

    /// @notice Converts a USD amount to its equivalent in ETH using Chainlink ETH/USD price feed
    function usdToEth(uint256 usdAmount) internal view returns (uint256) {
        (, int256 price, , ,) = ethUsdPriceFeed.latestRoundData();
        require(price > 0, "Invalid ETH price");
        // ETH/USD has 8 decimals. Convert to 18 decimals: price * 1e10
        uint256 ethPrice = uint256(price) * 1e10;
        return (usdAmount * 1e18) / ethPrice;
    }

    /// @notice Returns the current ETH/USD price (with 18 decimals)
    function getEthPrice() public view returns (uint256) {
        (, int256 price, , ,) = ethUsdPriceFeed.latestRoundData();
        return uint256(price) * 1e10; // Adjust to 18 decimals
    }

    /// @notice Returns current rainfall in mm
    function getCurrentRainfall() public view returns (uint256) {
        (, int256 rainfall, , ,) = weatherOracle.latestRoundData();
        return uint256(rainfall);
    }

    /// @notice Owner can withdraw all contract funds
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Accept ETH transfers directly
    receive() external payable {}

    /// @notice Fallback function to prevent ETH from getting stuck
    fallback() external payable {
        revert("Use purchaseInsurance()");
    }

    /// @notice Returns contract's current ETH balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}