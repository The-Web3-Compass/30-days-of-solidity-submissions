

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultMaster is Ownable {

    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    // Set deployer as owner using OpenZeppelin's constructor
    constructor() Ownable(msg.sender) {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() public payable {
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function withdraw(address _to, uint256 _amount) public onlyOwner {
        require(_amount <= getBalance(), "Insufficient balance");

        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed");

        emit WithdrawSuccessful(_to, _amount);
    }
}

