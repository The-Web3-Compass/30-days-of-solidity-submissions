// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";

contract VaultMaster is Ownable {

    event Deposit(address indexed account, uint256 value);
    event Withdrawal(address indexed recipient, uint256 value);

    // Retrieve the balance of the contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Deposit funds into the contract
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        emit Deposit(msg.sender, msg.value);
    }

    // Withdraw funds from the contract
    function withdraw(address payable _to, uint256 _amount) public onlyOwner {
        uint256 contractBalance = getBalance();
        require(_amount <= contractBalance, "Insufficient contract balance");

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Withdrawal failed");

        emit Withdrawal(_to, _amount);
    }
}
