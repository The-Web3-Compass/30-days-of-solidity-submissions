//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultMaster is Ownable{


    event DepositSuccessful(address acount,uint256 value);
    event WithdrawSuccessful(address acount,uint256 value);

     // 使用 OpenZeppelin 的构造函数将部署者设置为所有者
    // constructor() Ownable(msg.sender) {}

    function deposit() payable public{
        require(msg.value > 0,"Invalid value");
        emit DepositSuccessful(msg.sender,msg.value);
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function withdraw(address _to,uint256 _amount) public  onlyOwner{
        require(_amount <= getBalance(),"Insufficient Value");
        (bool success,) = payable(_to).call{value: _amount}("");
        require(success,"Call Failed");
        emit DepositSuccessful(_to, _amount);

    }



}
