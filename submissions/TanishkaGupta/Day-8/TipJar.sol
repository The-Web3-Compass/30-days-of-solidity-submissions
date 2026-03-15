// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TipJar {

    address public owner;
    uint public totalTips;

    constructor() {
        owner = msg.sender;
    }

    // Function to send tips
    function sendTip() public payable {
        require(msg.value > 0, "Send some ETH to tip");

        totalTips += msg.value;
    }

    // Check contract balance
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // Owner withdraws all tips
    function withdrawTips() public {
        require(msg.sender == owner, "Only owner can withdraw");

        uint balance = address(this).balance;

        (bool sent, ) = payable(owner).call{value: balance}("");
        require(sent, "Transfer failed");
    }
}