// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

/**
 * @title Simple Bank
 * @author Eric (https://github.com/0xxEric)
 * @notice A simple Ether Bank
 * @custom:project 30-days-of-solidity-submissions: Day06
 */

contract AdminOnly {
    address public admin;
    mapping(address => uint256) balance;
    mapping(address => bool) membership;

    event Deposit(address from, uint256 amount);
    event Withdraw(address to, uint256 amount);

    constructor() {
        admin = msg.sender;
    }

    modifier Onlyadmin() {
        require(msg.sender == admin, "Only admin can transfer the authority ");
        _;
    }

    function setMember(address member) external Onlyadmin {
        require(member != address(0), "zero address");
        membership[member] = true;
    }

    function desposit() external payable {
        require(membership[msg.sender] == true, "not member");
        require(msg.value > 0, "zero amount!");
        balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(membership[msg.sender] == true, "not member");
        require(balance[msg.sender] > amount, "insufficient!");
        balance[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
        emit Withdraw(msg.sender, amount);
    }
}
