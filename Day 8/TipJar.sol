// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TipJar {
    address public owner;
    mapping(string => uint256) public conversionRates;
    mapping(address => uint256) public totalTips;

    event TipReceived(address indexed from, uint256 amount, string currency, uint256 ethValue);
    event Withdraw(address indexed to, uint256 amount);
    event ConversionRateUpdated(string currency, uint256 newRate);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function tipEther() external payable {
        require(msg.value > 0, "No ETH sent");
        totalTips[msg.sender] += msg.value;
        emit TipReceived(msg.sender, msg.value, "ETH", msg.value);
    }

    function tipInCurrency(string calldata currency, uint256 amount) external payable {
        uint256 rate = conversionRates[currency];
        require(rate > 0, "Currency not supported");
        uint256 ethEquivalent = (amount * rate);
        require(msg.value == ethEquivalent, "Incorrect ETH sent for conversion");
        totalTips[msg.sender] += msg.value;
        emit TipReceived(msg.sender, amount, currency, ethEquivalent);
    }

    function setConversionRate(string calldata currency, uint256 rateInWei) external onlyOwner {
        conversionRates[currency] = rateInWei;
        emit ConversionRateUpdated(currency, rateInWei);
    }

    function withdraw(address payable to) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance");
        to.transfer(balance);
        emit Withdraw(to, balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
