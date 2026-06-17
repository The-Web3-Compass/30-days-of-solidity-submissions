// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;
    mapping(address => uint) public tips; 
    uint public totalTips;

    uint constant USD_RATE = 2000; // example: 1 ETH = $2000
    uint constant EUR_RATE = 1800; // example: 1 ETH = €1800

    constructor() {
        owner = msg.sender;
    }

    
    function tip() public payable {
        require(msg.value > 0, "Send some ETH");
        tips[msg.sender] += msg.value;
        totalTips += msg.value;
    }

    
    function toUSD(uint ethAmount) public pure returns (uint) {
        return ethAmount * USD_RATE / 1 ether;
    }

    
    function toEUR(uint ethAmount) public pure returns (uint) {
        return ethAmount * EUR_RATE / 1 ether;
    }

    
    function withdraw() public {
        require(msg.sender == owner, "Not the owner");
        payable(owner).transfer(address(this).balance);
    }

   
    function getTips(address user) public view returns (uint) {
        return tips[user];
    }
}
