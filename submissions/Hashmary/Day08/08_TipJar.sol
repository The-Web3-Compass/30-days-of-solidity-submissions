/*---------------------------------------------------------------------------
  File:   08_TipJar.sol
  Author: Marion Bohr
  Date:   04/08/2025
  Description:
    Build a multi-currency digital tip jar! Users can send Ether directly or 
    simulate tips in foreign currencies like USD or EUR. You'll learn how to 
    manage currency conversion, handle Ether payments using `payable` and 
    `msg.value`, and keep track of individual contributions. Think of it like 
    an advanced version of a 'Buy Me a Coffee' button — but smarter, more 
    global, and Solidity-powered.
    -------------------------
    Concepts You'll Master: 
        conversion
        denominations
        payable
    Learning Progression:
        Expands on basic Ether transfers by introducing access control, 
        tracking contributions, and simulating real-world currency handling — 
        preparing you for more complex contract logic.

----------------------------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract TipJar {
    address public owner;
    
    // Mapping to track user contributions (address -> currency -> amount)
    mapping(address => mapping(string => uint256)) public contributions;

    // Conversion rates (static for simplicity; in a real-world scenario, 
    // they could be dynamic)
    // Conversion rate: 1 ETH = 1000 USD, 1 ETH = 900 EUR (example rates)
    uint256 public usdToEthRate = 1000; // 1 ETH = 1000 USD
    uint256 public eurToEthRate = 900;  // 1 ETH = 900 EUR

    constructor() {
        owner = msg.sender;
    }

    // Modifier to restrict access to the owner for certain functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // Accepts Ether directly
    function tipInEther() public payable {
        require(msg.value > 0, "Must send some Ether");
        
        contributions[msg.sender]["ETH"] += msg.value;
    }

    // Accept tips in USD (simulated), converting based on the rate
    function tipInUSD(uint256 usdAmount) public {
        uint256 ethAmount = usdAmount * 1 ether / usdToEthRate;
        require(ethAmount > 0, "Converted amount should be greater than 0");

        contributions[msg.sender]["USD"] += usdAmount;
    }

    // Accept tips in EUR (simulated), converting based on the rate
    function tipInEUR(uint256 eurAmount) public {
        uint256 ethAmount = eurAmount * 1 ether / eurToEthRate;
        require(ethAmount > 0, "Converted amount should be greater than 0");

        contributions[msg.sender]["EUR"] += eurAmount;
    }

    // Check the total contributions of a user in a specific currency
    function checkContributions(address _user, string memory _currency) public view returns (uint256) {
        return contributions[_user][_currency];
    }

    // Owner can change the conversion rates
    function setConversionRates(uint256 _usdToEthRate, uint256 _eurToEthRate) public onlyOwner {
        usdToEthRate = _usdToEthRate;
        eurToEthRate = _eurToEthRate;
    }

    // Withdraw contract balance to the owner
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        payable(owner).transfer(balance);
    }

    // Fallback function to accept Ether
    receive() external payable {
        tipInEther();
    }
}    