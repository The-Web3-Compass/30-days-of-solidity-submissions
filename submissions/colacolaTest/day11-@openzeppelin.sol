// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import"@openzeppelin/contracts/access/Ownable.sol";

contract VaultMaster is Ownable{
    
    event DepositSuccessful(address indexed account, uint256 value, uint timestamp);
    event WithdrawSuccessful(address indexed recipient, uint256 value, uint timestamp);

    constructor() Ownable(msg.sender){}
 
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function deposit() public payable{
        require(msg.value > 0, "Invalid amount");
        emit DepositSuccessful(msg.sender, msg.value, block.timestamp);
    }

    function withdraw(address recipient, uint256 amount) public onlyOwner{
        require(amount > 0, "Invaild amount");
        require(getBalance() >= amount, "Not enough balance");
        require(recipient != address(0), "Invalid address");

        (bool success,) = payable(recipient).call{value: amount}("");
        require(success, "Transfer failed");
        emit WithdrawSuccessful(recipient, amount, block.timestamp);
    }
}

    

    
