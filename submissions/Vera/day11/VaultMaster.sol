// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// 自定义的ownable，测试完成，可用
// import "./Ownable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

//也可以在合约继承声明的这里这样写，在这个合约的情况下传递的参数是一样的
contract vaultMaster is Ownable(msg.sender) {

    // 向父合约函数的构造函数传入参数
    // constructor()Ownable(msg.sender){}

    event DepositSuccessful(address indexed account,uint256 value);
    event WithdrawSuccessful(address indexed recipient,uint256 value);

    function getBalance()public view returns(uint256){
        return address(this).balance;
    }

    function deposit()public payable{
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender,msg.value);
    } 
    
    function withdraw(address _to,uint256 _amount)public onlyOwner{
        require(_to!=address(0),"Invalid address");
        require(_amount<getBalance(),"Insufficient balance");

        (bool success,) = _to.call{value:_amount}("");
        require(success,"Transfer Failed");

        emit WithdrawSuccessful(_to, _amount);
    }
}