     
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FunTransfer {
    address public owner;
    uint256 public received;

    constructor() {
        owner = msg.sender;
    }

    function receiveEther() external payable {
        received += msg.value;
    }

    function withdrawEther() external {
        payable(owner).transfer(address(this).balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

