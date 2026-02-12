
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title TipJar
 * @dev A multi-currency digital tip jar where users can contribute Ether or simulate tips in USD and EUR.
 * Tracks user contributions in Ether, USD, and EUR using conversion rates.
 * Demonstrates `payable`, Ether transfers with `msg.value`, and event emission for tracking tips.
 */

contract TipJar {

    struct Contribution {
        uint256 etherAmount; // Ether contribution
        uint256 usdAmount;   // USD equivalent contribution
        uint256 eurAmount;   // EUR equivalent contribution
    }

    mapping(address => Contribution) public contributions;

    uint256 public usdToEtherRate = 2000; // 1 Ether = 2000 USD
    uint256 public eurToEtherRate = 1800; // 1 Ether = 1800 EUR

    event ContributionReceived(address indexed user, uint256 etherAmount, uint256 usdAmount, uint256 eurAmount);

    modifier hasBalance() {
        require(address(this).balance > 0, "No funds available.");
        _;
    }

    function contributeInEther() external payable {
        require(msg.value > 0, "You need to send some Ether.");

        contributions[msg.sender].etherAmount += msg.value;

        uint256 usdAmount = msg.value * usdToEtherRate;
        uint256 eurAmount = msg.value * eurToEtherRate;

        contributions[msg.sender].usdAmount += usdAmount;
        contributions[msg.sender].eurAmount += eurAmount;

        emit ContributionReceived(msg.sender, msg.value, usdAmount, eurAmount);
    }

    // Function to contribute in USD (simulated conversion)
    function contributeInUSD(uint256 usdAmount) external {
        uint256 etherAmount = usdAmount / usdToEtherRate;
        require(etherAmount > 0, "Amount is too small to convert.");

        payable(address(this)).transfer(etherAmount);

        contributions[msg.sender].etherAmount += etherAmount;
        contributions[msg.sender].usdAmount += usdAmount;

        emit ContributionReceived(msg.sender, etherAmount, usdAmount, 0);
    }

    // Function to contribute in EUR (simulated conversion)
    function contributeInEUR(uint256 eurAmount) external {
        uint256 etherAmount = eurAmount / eurToEtherRate;
        require(etherAmount > 0, "Amount is too small to convert.");

        payable(address(this)).transfer(etherAmount);

        contributions[msg.sender].etherAmount += etherAmount;
        contributions[msg.sender].eurAmount += eurAmount;

        emit ContributionReceived(msg.sender, etherAmount, 0, eurAmount);
    }

    function withdraw(uint256 amount) external hasBalance {
        require(amount <= address(this).balance, "Not enough balance.");
        payable(msg.sender).transfer(amount);
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTotalContribution(address user) external view returns (uint256 etherAmount, uint256 usdAmount, uint256 eurAmount) {
        Contribution memory contrib = contributions[user];
        return (contrib.etherAmount, contrib.usdAmount, contrib.eurAmount);
    }
}
