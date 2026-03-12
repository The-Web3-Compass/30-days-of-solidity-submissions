//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;


// Create a digital tip jar! Users can send Ether to support a creator. 
// You'll learn how to handle Ether payments (using `payable` and `msg.value`). 
// Think of it like a virtual 'Buy Me a Coffee' button,
// demonstrating how to receive Ether payments.

contract TipJar{ 
    address public owner;
    mapping(address => uint256) public sentByWhom;
    
    event CoffeeBought(address indexed sender, uint256 amount);

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function withdrawTipJar(uint256 _amountToWithdraw) public onlyOwner {
        require(address(this).balance >= _amountToWithdraw, "Insufficient Balance");
        (bool success, ) = payable(owner).call{value: _amountToWithdraw}("");
        require(success, "Failed to Withdraw");
    }

    function buyMeACoffee() public payable {
        require(msg.sender != address(0), "Invalid address");
        require(msg.value > 0, "Enter a valid amount to send");
        sentByWhom[msg.sender] += msg.value;
        emit CoffeeBought(msg.sender, msg.value);
    }

    function checkTipBalance() public view onlyOwner returns(uint256){
        return address(this).balance;
    }
}