// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//import "./Day11-Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultMaster is Ownable{//"VaultMaster 继承自 Ownable。"

constructor() Ownable(msg.sender) {}//// 使用 OpenZeppelin 的构造函数将部署者设置为所有者

event DepositSuccessful(address indexed account, uint256 value);//当有人向合约发送 ETH 时触发
event WithdrawSuccessful(address indexed recipient, uint256 value);//当所有者从合约提取 ETH 时触发

function getBalance() public view returns (uint256) {//返回合约当前持有的 ETH 数量。
    return address(this).balance;
}

function deposit() public payable{//允许任何人向合约发送 ETH。
    require(msg.value>0,"Enter a valid amount");
    emit DepositSuccessful(msg.sender, msg.value);
}

function withdraw(address _to, uint256 _amount) public onlyOwner{
    require(_amount<=getBalance(),"Insufficient balance");
    (bool success, ) = payable(_to).call{value:_amount}("");
    require(success, "Transfer Failed");

    emit WithdrawSuccessful(_to, _amount);
}

}