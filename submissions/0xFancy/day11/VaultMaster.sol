// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ownable.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//以太坊公开库


contract VaultMaster is Ownable {
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    //constructor() Ownable(msg.sender){};
    //OpenZeppelin 版本的 Ownable 期望你在部署合约时传递初始所有者。需要添加这个构造函数.

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
        require(success, "Transfer Failed");

        emit WithdrawSuccessful(_to, _amount);
    }
}

