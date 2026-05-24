// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract TipJar {

    address public owner;
    uint public totalTips;

    event Tipped(address indexed from, uint amount);

    constructor() {
        owner = msg.sender;
    }

    function support() external payable {
        require(msg.value > 0, "No ETH sent");

        totalTips += msg.value;

        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "Transfer failed");

        emit Tipped(msg.sender, msg.value);
    }
}