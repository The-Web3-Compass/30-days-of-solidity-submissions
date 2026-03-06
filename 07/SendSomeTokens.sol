// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SendSomeTokens {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function sendTokens(address payable _to, uint256 _amount) public {

        require(_to != address(0), "Invalid address");
        require(address(this).balance >= _amount, "Not enough balance");

        _to.transfer(_amount);
    }

    function deposit() public payable {
        require(msg.value > 0, "Send some ETH");
    }
}