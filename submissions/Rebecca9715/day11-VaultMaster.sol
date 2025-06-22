 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./day11-ownable.sol";

// 继承
contract VaultMaster is Ownable {
    // 记录存取款成功的日志
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);
    // 获取余额
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
// 存款
    function deposit() public payable {
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }
// 取款
    function withdraw(address _to, uint256 _amount) public onlyOwner {
        require(_amount <= getBalance(), "Insufficient balance");

        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer Failed");

        emit WithdrawSuccessful(_to, _amount);
    }
}

// owner：0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 
// address 1：0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 
// address 2：0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db

// Day11
// 1. 实际上是完成了一个对ownalbe的继承：contract VaultMaster is Ownable，但是这里可以进行一些改动
// 2. 其他操作较为简单，基本上是存取款操作



