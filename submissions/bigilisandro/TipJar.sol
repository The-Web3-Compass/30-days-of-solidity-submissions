// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;
    uint256 public tipAmount;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function addTip() public payable {
        require(msg.value > 0, "Must send ETH");
        tipAmount += msg.value;
    }

    function getTipAmount() public view returns (uint256) {
        return tipAmount;
    }

    function withdrawTip() public onlyOwner {
        require(tipAmount > 0, "No tips to withdraw");
        payable(owner).transfer(tipAmount);
        tipAmount = 0;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
