//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank{

    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) balance;

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
    }

    modifier onlyBankManager(){
        require(msg.sender == bankManager, "Administrative Privilege");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Member has not registered");
        _;
    }

    function addMembers(address newmember)public onlyBankManager{
        require(newmember != address(0), "Invalid address");
        require(newmember != msg.sender, "Bank Manager is already a member");
        require(!registeredMembers[newmember], "Member has already registered");
        registeredMembers[newmember] = true;
        members.push(newmember);
    }

     function checkMembers() public view returns(address[] memory){
        return members;
    }

    function depositAmountEther() public payable onlyRegisteredMember{  
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] = balance[msg.sender]+msg.value;
   
    }

    function withdrawAmount(uint256 amount) public onlyRegisteredMember{
        require(amount > 0, "Amount must be greater than 0");
        require(amount<= balance[msg.sender], "Insufficient balance");
        balance[msg.sender] -= amount;
   
    }
    function getBalance(address _member) public view onlyRegisteredMember returns (uint256) {
        require(_member != address(0), "Invalid address");
        return balance[_member];
    } 
}