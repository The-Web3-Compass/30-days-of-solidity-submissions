// SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

//import "./day11-Ownable.sol";

//使用依赖库
import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultMaster is Ownable{
    event DepositSuccessful(address indexed account,uint256 value);
    event WithdrawSuccessful(address indexed recipient,uint256 value);

    //使用依赖库必须引入
    constructor() Ownable(msg.sender){}

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }

    function deposit() public payable{
        require(msg.value > 0,"Amount must be greater than zero");
        emit DepositSuccessful(msg.sender,msg.value);
    }
    function withdraw(address _to,uint256 _amount)public onlyOwner{
        require(_amount<=getBalance(),"Insufficient balance");
        (bool success,)=payable (_to).call{value:_amount}("");
        require(success,"Transfer Failed");
        emit WithdrawSuccessful(_to, _amount);
    }
}