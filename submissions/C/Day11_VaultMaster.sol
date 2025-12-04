// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "Day11_Ownable.sol"; // 手写Ownable
import "@openzeppelin/contracts/access/Ownable.sol"; // 使用库OpenZeppelin

// 引入文件代码续 is Ownable 进行继承
contract VaultMaster is Ownable {
    
    event DepositSuccessful(address indexed account, uint256 value); // 存事件
    event WithdrawSuccessful(address indexed recipient, uint256 value);// 取事件

    constructor() Ownable(msg.sender) {}

    // 获取当前合约总余额
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    // 存
    function deposit() public payable{
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }
    // 取
    function withdraw(address _to, uint256 _amount)public onlyOwner{
        require(_amount <= getBalance());
        (bool success,) = payable(_to).call{value: _amount}("");
        require(success, "Transfer Failed");

        emit WithdrawSuccessful(_to, _amount);
    }
}