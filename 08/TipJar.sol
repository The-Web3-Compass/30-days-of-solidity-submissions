// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {

    address public owner;

    mapping(address => uint256) public contributions;

    uint256 public usdRate = 2000;
    uint256 public eurRate = 1800;

    constructor() {
        owner = msg.sender;
    }

    function tipETH() public payable {
        require(msg.value > 0);
        contributions[msg.sender] += msg.value;
    }

    function tipUSD(uint256 amount) public payable {
        require(amount > 0);
        uint256 ethAmount = amount * 1 ether / usdRate;
        require(msg.value >= ethAmount);
        contributions[msg.sender] += msg.value;
    }

    function tipEUR(uint256 amount) public payable {
        require(amount > 0);
        uint256 ethAmount = amount * 1 ether / eurRate;
        require(msg.value >= ethAmount);
        contributions[msg.sender] += msg.value;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function withdraw() public {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }
}