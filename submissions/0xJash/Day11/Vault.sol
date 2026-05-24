// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Ownable.sol";

contract Vault is Ownable{

    event Deposited(address indexed depositor, uint amount);
    event Withdrawn(address indexed recipient, uint amount);

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount cannot be empty");
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(address recipient, uint amount) public onlyOwner {
        require(recipient != address(0), "Invalid recipient");
        require(amount <= address(this).balance, "Insufficient balance");

        (bool s, ) = payable(recipient).call{value: amount}("");
        require(s, "Transfer failed");
        emit Withdrawn(recipient, amount);
    }

    function balance() public view returns(uint) {
        return address(this).balance;
    }
} 