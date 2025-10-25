// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ETherPiggyBank{
    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) balance;

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender],"Member not registered");
        _;
    }

    function addMembers() public view returns(address[] memory){
        return members;
    }

    function depositAmountEther() public payable onlyRegisteredMember{
        require(msg.value > 0,"Invalid amount");
        balance[msg.sender] += msg.value;
    }

    function withdrawAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >=_amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
    }

    function getBalance(address _member) public view returns (uint256){
        require(_member !=address(0), "Invalid address");
        return balance[_member];
    }
}