// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultMaster is Ownable {
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    // 使用 openzeppelin 的 Ownable 合约，并传递初始所有者
    constructor() Ownable(msg.sender){}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() public payable {
        require(msg.value > 0, "Invalid amount");

        emit DepositSuccessful(msg.sender, msg.value);
    }

    function withdraw(address _receipt, uint256 _amount) public onlyOwner {
        require(_amount <= getBalance(), "Insufficient balance");

        (bool success, ) = payable(_receipt).call{value: _amount}("");
        require(success, "Transfer failed");

        emit WithdrawSuccessful(_receipt, _amount);
    }
}