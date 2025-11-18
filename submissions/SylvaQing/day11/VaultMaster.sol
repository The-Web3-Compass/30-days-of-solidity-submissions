// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

// import "./ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultMaster is Ownable{
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    //使用包的构造函数
    constructor() Ownable(msg.sender){}

    //获取余额
    function getBalance()public view returns (uint256){
        return address(this).balance;
    }
    //存款
    function deposit()public  payable {
        require(msg.value>0,"Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);

    }
    //撤回
    function withdraw(address _to,uint256 _amount)public onlyOwner{
        require(_amount<=getBalance(), "Insufficient balance");
        (bool success,)=payable (_to).call{value:_amount}("");
        require(success,"Transfer Failed");

        emit WithdrawSuccessful(_to,_amount);
    }
    

}