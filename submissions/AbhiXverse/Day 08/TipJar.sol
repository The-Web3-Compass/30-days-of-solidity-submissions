// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract TipJar {

    address public owner;                   // Owner of the contract
    uint256 public totalTips;               // total tips in Ether received

    uint256 EthToUSD = 1450;                // exchange rate for ETH to USD 
    uint256 EthToINR = 126000;              // exchange rate for ETH to INR 
    
    uint256 totalUSD;                       // total USD equivalent of tips
    uint256 totalINR;                       // total INR equivalent of tips

    // mapping to store tips by address
    mapping(address => uint256) public tipsByAddress;

    // struct to store supporter details
    struct Supporter {
        string name;
        uint256 amountInWei;              // Amount of Ether (in Wei)
    }


    // Array to store all supporters
    Supporter[] public supporters;

    // Constructor to set the contract deployer as the owner
    constructor() {
        owner = msg.sender;
    }

    // Modifier to restrict access to only the owner
    modifier admin() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // Function to accept tips from users
    function sendTip(string memory _name) public payable {
        require(msg.value > 0, "Tip must be more than 0");
        supporters.push(Supporter(_name, msg.value));          // Store the supporter info
        tipsByAddress[msg.sender] += msg.value;                // Update the total tips by address
        
        totalTips += msg.value;                                // Update the total tips received

        // Calculate USD and INR equivalents
        uint256 USD = (msg.value * EthToUSD) / 1e18; 
        uint256 INR = (msg.value * EthToINR) / 1e18;
        totalUSD += USD;                                        // Update the total USD
        totalINR += INR;                                        // Update the total INR
    }

    // Function to get the total USD equivalent of all tips
    function getUSD() public view returns (uint256) {
        return totalUSD;
    }

    // Function to get the total INR equivalent of all tips
    function getINR() public view returns (uint256) {
        return totalINR;
    }

    // Function to withdraw all tips (only for the owner)
    function withdraw() public admin {
        payable(owner).transfer(address(this).balance);
    }

    // Function to get the total number of supporters
    function TotalSupporters() public view returns (uint256) {
        return supporters.length;
    }
}
