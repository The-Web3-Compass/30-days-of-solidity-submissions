// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Day11 ownable.sol";

contract VaultMaster is Ownable {
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() public payable {
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function withdraw(address recipient, uint256 amount) public onlyOwner {
        require(amount <= getBalance(), "Insufficient balance");

        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Transfer Failed");

        emit WithdrawSuccessful(recipient, amount);
    }
}

