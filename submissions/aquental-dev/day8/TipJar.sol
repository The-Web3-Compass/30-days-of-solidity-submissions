// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TipJar {
    // State variables
    address public owner;
    AggregatorV3Interface public ethUsdPriceFeed;
    AggregatorV3Interface public ethEurPriceFeed;
    mapping(address => uint256) public contributionsWei;
    mapping(address => uint256) public contributionsUsdCents;
    mapping(address => uint256) public contributionsEurCents;
    uint256 public totalTipsWei;

    // Events
    event TipReceived(
        address indexed sender,
        uint256 amountWei,
        string currency,
        uint256 amountInCurrency
    );
    event Withdrawn(address indexed owner, uint256 amountWei);

    // Constructor
    constructor(address _ethUsdPriceFeed, address _ethEurPriceFeed) {
        owner = msg.sender;
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        ethEurPriceFeed = AggregatorV3Interface(_ethEurPriceFeed);
    }

    // Fallback function to accept direct Ether tips
    receive() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        contributionsWei[msg.sender] += msg.value;
        totalTipsWei += msg.value;
        emit TipReceived(msg.sender, msg.value, "ETH", msg.value);
    }

    // Estimate Wei required for a given USD cents amount
    function estimateEther2USD(uint256 usdCents) public view returns (uint256) {
        require(usdCents > 0, "USD amount must be greater than 0");
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        require(price > 0, "Invalid USD price feed");
        // Calculate Wei: usdCents * 10^18 * 10^8 / (ETH/USD price * 10^8 * 100)
        return (usdCents * 1e18 * 1e8) / uint256(price) / 100;
    }

    // Estimate Wei required for a given EUR cents amount
    function estimateEther2EUR(uint256 eurCents) public view returns (uint256) {
        require(eurCents > 0, "EUR amount must be greater than 0");
        (, int256 price, , , ) = ethEurPriceFeed.latestRoundData();
        require(price > 0, "Invalid EUR price feed");
        // Calculate Wei: eurCents * 10^18 * 10^8 / (ETH/EUR price * 10^8 * 100)
        return (eurCents * 1e18 * 1e8) / uint256(price) / 100;
    }

    // Function to tip in USD (converts to ETH)
    function tipInUsd(uint256 usdCents) external payable {
        uint256 requiredWei = estimateEther2USD(usdCents);
        require(msg.value >= requiredWei, "Insufficient ETH for USD tip");

        contributionsWei[msg.sender] += msg.value;
        contributionsUsdCents[msg.sender] += usdCents;
        totalTipsWei += msg.value;
        emit TipReceived(msg.sender, msg.value, "USD", usdCents);

        // Refund excess ETH if sent
        if (msg.value > requiredWei) {
            payable(msg.sender).transfer(msg.value - requiredWei);
        }
    }

    // Function to tip in EUR (converts to ETH)
    function tipInEur(uint256 eurCents) external payable {
        uint256 requiredWei = estimateEther2EUR(eurCents);
        require(msg.value >= requiredWei, "Insufficient ETH for EUR tip");

        contributionsWei[msg.sender] += msg.value;
        contributionsEurCents[msg.sender] += eurCents;
        totalTipsWei += msg.value;
        emit TipReceived(msg.sender, msg.value, "EUR", eurCents);

        // Refund excess ETH if sent
        if (msg.value > requiredWei) {
            payable(msg.sender).transfer(msg.value - requiredWei);
        }
    }

    // Function to withdraw all tips (only owner)
    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");

        totalTipsWei = 0;
        payable(owner).transfer(amount);
        emit Withdrawn(owner, amount);
    }

    // Function to get total contributions for an address
    function getContributions(
        address contributor
    )
        external
        view
        returns (uint256 weiAmount, uint256 usdCents, uint256 eurCents)
    {
        return (
            contributionsWei[contributor],
            contributionsUsdCents[contributor],
            contributionsEurCents[contributor]
        );
    }

    // Function to get current ETH price in USD and EUR
    function getCurrentPrices()
        external
        view
        returns (uint256 ethUsdPrice, uint256 ethEurPrice)
    {
        (, int256 usdPrice, , , ) = ethUsdPriceFeed.latestRoundData();
        (, int256 eurPrice, , , ) = ethEurPriceFeed.latestRoundData();
        return (uint256(usdPrice), uint256(eurPrice));
    }
}

/*
https://docs.chain.link/data-feeds/price-feeds/addresses?page=1&testnetPage=1&network=ethereum&search=eth+%2F+us&testnetSearch=usd
Sepolia
ETH / USD - 0x694AA1769357215DE4FAC081bf1f309aDC325306
EUR / USD - 0x1a81afB8146aeFfCFc5E50e8479e826E7D55b910


0x000000000000000000000000694aa1769357215de4fac081bf1f309adc3253060000000000000000000000001a81afb8146aeffcfc5e50e8479e826e7d55b910
*/
