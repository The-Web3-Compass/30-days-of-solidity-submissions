// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FunTransfer is ReentrancyGuard {
    address public immutable owner;
    uint256 public totalReceived;

    event EtherReceived(address indexed sender, uint256 amount, uint256 newTotal);
    event EtherWithdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can withdraw");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        receiveEther();
    }

    function receiveEther() public payable nonReentrant {
        require(msg.value > 0, "Must send some ETH");
        totalReceived += msg.value;
        emit EtherReceived(msg.sender, msg.value, totalReceived);
    }

    function withdrawEther() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");

        emit EtherWithdrawn(owner, balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}