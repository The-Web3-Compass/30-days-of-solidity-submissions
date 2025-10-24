// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;
/*
   Build a secure Vault contract that only the owner (master key holder) can control. 
   You'll split your logic into two parts: a reusable 'Ownable' base contract and 
   a 'VaultMaster' contract that inherits from it. Only the owner can withdraw funds or transfer ownership. 
   This shows how to use Solidity's inheritance model to write clean, reusable access control patterns — 
   just like in real-world production contracts. 
   It's like building a secure digital safe where only the master key holder can access or delegate control.
*/    

//import "./Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultMaster is Ownable {
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

     constructor() Ownable(msg.sender) {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() public payable {
        require(msg.value > 0, "Enter valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function withdraw(address _from, uint256 _amount) public onlyOwner {
        require(_amount <= getBalance(), "Insufficient balance");
        (bool success, ) = payable(_from).call{value: _amount}("");
        require(success, "Operation Failed");
        emit WithdrawSuccessful(_from, _amount);
    }
}