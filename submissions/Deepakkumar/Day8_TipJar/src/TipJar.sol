// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TipJar {
    address public owner;
    uint256 public totalTips;

    mapping(address => uint256) public contributions;

    // Conversion rates (1 ETH = X currency units)
    uint256 public usdToEthRate = 2000; // 1 ETH = 2000 USD
    uint256 public eurToEthRate = 1800; // 1 ETH = 1800 EUR

    event TipReceived(address indexed from, uint256 amount, string currency);
    event Withdrawn(address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    ///  Directly send Ether as a tip
    function sendTip() external payable {
        require(msg.value > 0, "Tip must be greater than 0");
        contributions[msg.sender] += msg.value;
        totalTips += msg.value;
        emit TipReceived(msg.sender, msg.value, "ETH");
    }

    /// Simulate tip in USD
    function sendTipInUSD(uint256 usdAmount) external payable {
        uint256 ethEquivalent = (usdAmount * 1 ether) / usdToEthRate;
        require(msg.value >= ethEquivalent, "Insufficient ETH sent for USD value");

        contributions[msg.sender] += msg.value;
        totalTips += msg.value;
        emit TipReceived(msg.sender, msg.value, "USD");
    }

    /// Simulate tip in EUR
    function sendTipInEUR(uint256 eurAmount) external payable {
        uint256 ethEquivalent = (eurAmount * 1 ether) / eurToEthRate;
        require(msg.value >= ethEquivalent, "Insufficient ETH sent for EUR value");

        contributions[msg.sender] += msg.value;
        totalTips += msg.value;
        emit TipReceived(msg.sender, msg.value, "EUR");
    }

    ///Get the total tips sent by a specific user
    function getContribution(address tipper) external view returns (uint256) {
        return contributions[tipper];
    }

    /// Withdraw all funds (only owner)
    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit Withdrawn(owner, balance);
    }

    /// Owner can update currency conversion rates
    function setRates(uint256 _usdRate, uint256 _eurRate) external {
        require(msg.sender == owner, "Only owner can update rates");
        usdToEthRate = _usdRate;
        eurToEthRate = _eurRate;
    }

    /// Accept plain ETH transfers
    receive() external payable {
        contributions[msg.sender] += msg.value;
        totalTips += msg.value;
        emit TipReceived(msg.sender, msg.value, "ETH");
    }
}
