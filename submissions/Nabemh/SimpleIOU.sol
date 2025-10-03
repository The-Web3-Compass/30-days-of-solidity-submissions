// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleIOU {

    address owner;
    
    mapping(address => bool) registered;
    address[] registeredFriends;
    mapping(address => uint) userBalance;
    mapping(address => mapping(address => uint)) public debts;

    constructor(){
        owner = msg.sender;
        registered[msg.sender] = true;
        registeredFriends.push(msg.sender);
    }

    modifier onlyOwner(){
        require (msg.sender == owner, "You are not authorized!");
        _;
    }

    modifier onlyRegistered(){
        require (registered[msg.sender], "Not registered!");
        _;
    }

    function addMember(address newFriend) onlyOwner public {
        require (newFriend != address(0), "Not a valid address!");
        require(!registered[newFriend], "Already registered!");
        registeredFriends.push(newFriend);

    }

    function removeMember(address friend) onlyOwner public {
        require (friend != address(0), "Not a valid address!");
        require(registered[friend], "Not registered!");
        
        uint256 totalFriends = registeredFriends.length;

        for (uint256 i=0; i < totalFriends; ++i) {
            if(registeredFriends[i] == friend){
                registeredFriends[i] = registeredFriends[totalFriends - 1];
                registeredFriends.pop();
                break;
            }
        }
        registered[friend] = false;
    }

    function deposit() onlyRegistered payable external {
        uint256 amount = msg.value;
        require (amount > 0, "Must be more than 0");
        userBalance[msg.sender] += amount;
    }

    function recordDept(address deptor, address creditor, uint256 amount) onlyRegistered public{
        require (deptor != address(0) && creditor != address(0), "Not a valid address!");
        require (amount > 0, "Not a valid address!");
        
        debts[deptor][creditor] += amount;

    }

    function payDept(address deptor, address creditor, uint256 amount) onlyRegistered public{
        require (deptor != address(0) && creditor != address(0), "Not a valid address!");
        require (amount > 0, "Not a valid address!");
        require (userBalance[deptor] >= amount, "Insufficient funds!");
        require ((debts[deptor][creditor]) > 0, "No depts recorded");
        
        debts[deptor][creditor] -= amount;
        userBalance[deptor] -= amount;
        userBalance[creditor] += amount;

    }

    function getDept(address deptor, address creditor) onlyRegistered public view returns (uint256){
        require (deptor != address(0) && creditor != address(0), "Not a valid address!");
        return debts[deptor][creditor];
    }

    function transferFunds(address payable recipient, uint256 amount) onlyRegistered public {
        require (recipient != address(0), "Not a valid address");
        require (amount > 0, "Enter valid amount");

        (bool success, ) = recipient.call{value: amount}("");
        userBalance[recipient] += amount;
        require(success, "Payment failed.");
    }


    function withdraw(address payable user, uint256 amount) onlyRegistered public {
        require (user != address(0), "Not a valid address!");
        require (userBalance[user] > 0 && userBalance[user] >= amount, "Insufficient funds!");

        (bool success, ) = user.call{value: amount}("");
        userBalance[user] -= amount;
        require(success, "Withdrawal failed");
    }

    function getBalance(address user) onlyRegistered public view returns (uint256){
        require (user != address(0), "Not a valid address!");
        return userBalance[user];
    }

}