// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

contract SimpleIOU {

    // store how much ether each user has 
    mapping (address => uint256) public balances;

    // store how much ether each user owes to another user
    mapping(address => mapping(address => uint256)) public debts;

    // deposit ether into the contract
    function deposit() public payable {
        require(msg.value > 0, "send some Eth");
        balances[msg.sender] += msg.value;
    }

    // function for borrowing Eth from your friend 
    function borrow(address friend, uint256 amount) public {
        require(amount > 0, "amount should be > 0");
        require(balances[friend] > amount, "friend doesn't have enough balance");
        balances[friend] -= amount;
        debts[msg.sender][friend] += amount;
        payable(msg.sender).transfer(amount);
    }

    // function for repaying Eth back to your friend 
    function rePay(address friend) public payable {
        require(debts[msg.sender][friend] > 0, "No debt");
        require(msg.value > 0, "amount should be > 0");
        require(msg.value <= debts[msg.sender][friend], "amount is more than debt");
        debts[msg.sender][friend] -= msg.value;  
        balances[friend] += msg.value; 
     }

     // this checks how much you owe to a specific friend
     function myDebt(address friend) public view returns (uint256) {
        return debts[msg.sender][friend];
     } 

     // this checks how much Eth a user stored in the contract 
     function checkbalance(address user) public view returns (uint256) {
        return balances[user];
     }
}
