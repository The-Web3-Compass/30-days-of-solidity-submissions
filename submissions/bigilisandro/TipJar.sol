// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;
    uint256 public totalTipsReceived;
    mapping(string => uint256) public conversionRates;
    string[] public supportedCurrencies;
    mapping(address => uint256) public tipperContributions;
    mapping(string => uint256) public tipsPerCurrency;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function addTip() public payable {
        require(msg.value > 0, "Must send ETH");
        totalTipsReceived += msg.value;
    }

    function getTipAmount() public view returns (uint256) {
        return totalTipsReceived;
    }

    function withdrawTip() public onlyOwner {
        require(totalTipsReceived > 0, "No tips to withdraw");
        payable(owner).transfer(totalTipsReceived);
        totalTipsReceived = 0;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
