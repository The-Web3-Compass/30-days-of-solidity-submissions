//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./day11-Ownable.sol";

contract VaultMaster is Ownable {
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function deposit () public payable {
        require(msg.value > 0, "Invalid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function withdraw(address recipient, uint256 amount) public onlyOwner {
        require(amount <= getBalance(), "Not enough balance");

        (bool success,) = payable(recipient).call {value: amount}("");
        require(success, "Transfer failed");

        emit WithdrawSuccessful(recipient, amount);
    }


}
