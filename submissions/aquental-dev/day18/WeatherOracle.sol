// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// WeatherOracle contract for decentralized crop insurance with Chainlink oracle integration
contract WeatherOracle is Ownable {
    // Chainlink oracle interface for rainfall data
    AggregatorV3Interface internal rainfallDataFeed;

    // Insurance policy details
    struct Policy {
        address farmer; // Farmer's wallet address
        uint256 premium; // Premium paid in wei
        uint256 payout; // Payout amount in wei
        uint256 rainfallThreshold; // Rainfall threshold in mm
        uint256 startTime; // Policy start timestamp
        uint256 endTime; // Policy end timestamp
        bool claimed; // Whether payout has been claimed
    }

    // Mapping of policy ID to Policy details
    mapping(uint256 => Policy) public policies;
    uint256 public policyCount;

    // ETH/USD price feed for payout calculations
    AggregatorV3Interface internal ethUsdPriceFeed;

    // Events for logging
    event PolicyCreated(
        uint256 policyId,
        address farmer,
        uint256 premium,
        uint256 payout,
        uint256 rainfallThreshold,
        uint256 startTime,
        uint256 endTime
    );
    event PayoutClaimed(uint256 policyId, address farmer, uint256 amount);
    event RainfallDataRequested(uint256 policyId, bytes32 requestId);
    event RainfallDataReceived(uint256 policyId, uint256 rainfall);

    // Constructor to initialize oracle addresses
    constructor(
        address _rainfallDataFeed,
        address _ethUsdPriceFeed
    ) Ownable(msg.sender) {
        rainfallDataFeed = AggregatorV3Interface(_rainfallDataFeed);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    }

    // Create a new insurance policy
    function createPolicy(
        uint256 _payoutUsd,
        uint256 _rainfallThreshold,
        uint256 _duration
    ) external payable {
        require(_payoutUsd > 0, "Payout must be greater than 0");
        require(
            _rainfallThreshold > 0,
            "Rainfall threshold must be greater than 0"
        );
        require(_duration > 0, "Duration must be greater than 0");

        // Calculate required premium (10% of payout for simplicity)
        uint256 ethPrice = uint256(getLatestEthPrice());
        uint256 payoutWei = (_payoutUsd * 1e18) / ethPrice;
        uint256 premiumWei = payoutWei / 10;
        require(msg.value >= premiumWei, "Insufficient premium paid");

        // Store policy
        policies[policyCount] = Policy({
            farmer: msg.sender,
            premium: msg.value,
            payout: payoutWei,
            rainfallThreshold: _rainfallThreshold,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            claimed: false
        });

        emit PolicyCreated(
            policyCount,
            msg.sender,
            msg.value,
            payoutWei,
            _rainfallThreshold,
            block.timestamp,
            block.timestamp + _duration
        );
        policyCount++;
    }

    // Fetch latest ETH/USD price from Chainlink price feed
    function getLatestEthPrice() public view returns (int) {
        try rainfallDataFeed.latestRoundData() returns (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) {
            require(timeStamp > 0, "Price feed not updated");
            require(price > 0, "Invalid price data");
            return price;
        } catch {
            revert("Price feed query failed");
        }
    }

    // Request rainfall data for a specific policy
    function requestRainfallData(uint256 _policyId) external {
        require(_policyId < policyCount, "Invalid policy ID");
        require(
            msg.sender == policies[_policyId].farmer,
            "Only policy owner can request"
        );
        require(
            block.timestamp <= policies[_policyId].endTime,
            "Policy expired"
        );
        require(!policies[_policyId].claimed, "Payout already claimed");

        // In a production environment, this would use Chainlink's request-response model
        // For simplicity, we simulate fetching rainfall data
        bytes32 requestId = bytes32(uint256(_policyId)); // Simulated request ID
        emit RainfallDataRequested(_policyId, requestId);

        // Simulate oracle response (in production, this would be a callback)
        int rainfall = getLatestRainfallData();
        fulfillRainfallData(_policyId, requestId, rainfall);
    }

    // Fetch latest rainfall data from Chainlink data feed
    function getLatestRainfallData() public view returns (int) {
        try rainfallDataFeed.latestRoundData() returns (
            uint80 roundID,
            int rainfall,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) {
            require(timeStamp > 0, "Rainfall data not updated");
            require(rainfall >= 0, "Invalid rainfall data");
            return rainfall;
        } catch {
            revert("Rainfall data query failed");
        }
    }

    // Process rainfall data and handle payout
    function fulfillRainfallData(
        uint256 _policyId,
        bytes32 _requestId,
        int _rainfall
    ) internal {
        Policy storage policy = policies[_policyId];
        require(!policy.claimed, "Payout already claimed");
        require(block.timestamp <= policy.endTime, "Policy expired");

        emit RainfallDataReceived(_policyId, uint256(_rainfall));

        // Check if rainfall is below threshold
        if (uint256(_rainfall) < policy.rainfallThreshold) {
            policy.claimed = true;
            (bool success, ) = policy.farmer.call{value: policy.payout}("");
            require(success, "Payout transfer failed");
            emit PayoutClaimed(_policyId, policy.farmer, policy.payout);
        }
    }

    // Withdraw contract balance (for owner)
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // Update oracle addresses (for owner)
    function updateOracleAddresses(
        address _rainfallDataFeed,
        address _ethUsdPriceFeed
    ) external onlyOwner {
        rainfallDataFeed = AggregatorV3Interface(_rainfallDataFeed);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    }
}
