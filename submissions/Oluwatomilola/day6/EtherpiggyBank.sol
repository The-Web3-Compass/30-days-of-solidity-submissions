// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

//piggybank strictly 4 friends saving in Eth
//require an admin to manage the piggybank
//friends should only be able to join on admin's approval 
//deposit
//check balance
//withdraw

contract EtherPiggyBank {

    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers; 
    mapping(address => uint256) public balance;
     
    constructor() {
       bankManager = msg.sender; 
       members.push(msg.sender);
    }

    modifier onlyBankmanager() {
        require(msg.sender == bankManager, "only bankmanager can perform this action");
        _;
    }

    modifier onlyregisteredMembers() {
        require(registeredMembers[msg.sender], "you're not a bonafide member");
        _;
    }

    function addMembers(address _member) public onlyBankmanager {
        require(_member != address(0), "Invalid address");
        require(_member = msg.sender, "Bank manager is already a member");
        require(!registeredMembers = _member, "not a new member");

        registeredMembers[_member] = true;
        members.push(_member);
    }

    function getMembers() public view returns(address[] memory) {
        return members;
    }

    function depositAmtInEth(uint256 _amount) public payable onlyregisteredMembers {
        require(_amount > 0, "Invalid amount");
        balance[msg.sender] += _amount;
    }

    
    function withdraw(uint256 _amount) public payable onlyregisteredMembers {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
    }

    
    


}