// SPDX-License-Identifier : MIT
pragma solidity ^0.8.20;

//import "./Day10Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; //从openzeppelin库包中获取内容

contract VaultMaster is Ownable{
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    constructor() Ownable(msg.sender){} //openzeppelin要求传递初始所有者给owner

    function getBalance() public view returns(uint256){
        return address(this).balance; //this表示这个合约，因此返回这个合约当前的ETH数量
    }

    function deposit() public payable{
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function withdraw(address _to, uint256 _amount) public onlyOwner{ //只能由所有者提取
        require(_amount <= getBalance(), "Insufficient balance");
        (bool success, ) = payable(_to).call{value:_amount}(""); //使用.call将指定的金额发送到给定的地址
        require(success, "Transfer Failed");

        emit WithdrawSuccessful(_to, _amount);
    }
}

