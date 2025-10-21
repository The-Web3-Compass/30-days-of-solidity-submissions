// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

//import "./Ownable.sol"

import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultMaster is Ownable{

    constructor() Ownable(msg.sender){}


    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawalSuccessful(address indexed recipient, uint256 value);

    function deposit()public payable {
        require(msg.value > 0 ,"Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function getBalance ()public view returns(uint256){
        return address(this).balance;
    }

    function withdraw(address _to, uint256 _amount)public onlyOwner{

        require(_amount <= getBalance(),"Insufficient Balance");
        (bool success,)= payable (_to).call{value: _amount}("");
        require(success, "Transfer Failed");
        emit WithdrawalSuccessful(_to, _amount);
    }


}
