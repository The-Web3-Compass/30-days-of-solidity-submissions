// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract TipJar {
    address public owner;

    // Track ETH tips
    mapping(address => uint) public ethTips;

    // Tracks USD/EUR tips
    mapping(address => uint256) public usdTips;
    mapping(address => uint256) public eurTips;

    // MOCK values
    uint256 public usdToEthRate = 0.0005 ether;
    uint256 public eurToEthRate = 0.0006 ether;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Accept ETH tips
    function tipInETH(address _address) external payable {
        ethTips[_address] += msg.value;
        payable(_address).transfer(msg.value);
    }

    // Simulate tip in USD
    function tipInUSD(uint256 usdAmount) external payable {
        uint256 requiredEth = usdAmount * usdToEthRate;
        require(msg.value >= requiredEth, "Insufficient ETH sent for USD tip");
        usdTips[msg.sender] += usdAmount;
        ethTips[msg.sender] += msg.value;
    }

    // Simulate tip in EUR
    function tipInEUR(uint256 eurAmount) external payable {
        uint256 requiredEth = eurAmount * eurToEthRate;
        require(msg.value >= requiredEth, "Insufficient ETH sent for EUR tip");
        eurTips[msg.sender] += eurAmount;
        ethTips[msg.sender] += msg.value;
    }

    // check total tips
    function totalTipsCollected() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
