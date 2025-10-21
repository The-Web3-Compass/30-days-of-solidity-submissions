// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

/**
 * @title Simple TipJar
 * @author Eric (https://github.com/0xxEric)
 * @notice A simple TipJar that receive ETH fee
 * @custom:project 30-days-of-solidity-submissions: Day08
 */

contract TipJar {
    address public admin;
    mapping(address=>uint256) public tipRecord;
    uint256 public totalAmount;
    event PayFee(address payer, uint256 amount);
    event Withdraw(address receipt, uint256 amount);
    constructor() {
        admin = msg.sender;
    }

    modifier Onlyadmin() {
        require(msg.sender == admin, "Only admin can transfer the authority ");
        _;
    }

    function adminTransfer(address newadmin)  Onlyadmin public{
        require(newadmin != address(0), "zero address");
        admin=newadmin;
    }

    function payFee() payable external{
        tipRecord[msg.sender]+=msg.value;
        totalAmount+=msg.value;
        emit PayFee(msg.sender, msg.value);
    }

    function withdraw(address receipt, uint256 amount) Onlyadmin external {
        require(receipt != address(0), "zero address");
        require(amount > 0, "amount should >0");
        require(amount <=totalAmount, "insufficient");        
        totalAmount -= amount;
        (bool success, ) = receipt.call{value: amount}("");
        require(success, "Withdrawal failed");
        emit Withdraw(receipt, amount);
    }
}