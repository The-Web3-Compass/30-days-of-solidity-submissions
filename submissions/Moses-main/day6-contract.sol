// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract EtherPiggyBank {

    address public bankManager;

    address[] members;
    mapping(address => bool) public registeredMembers;

    mapping(address => uint256) balance;


    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
        registeredMembers[msg.sender] = true;
    }


    modifier onlyBankManager(){
        require(msg.sender == bankManager, "Only bank manager can perfrom this action");
        _;
    }

    modifier onlyRegisteredMember{
        require(registeredMembers[msg.sender], "You must be a registered member to perform this action");
        _;
    }

    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Bank Manager is already a member");
        require(!registeredMembers[_member], "Member already registered");

        registeredMembers[_member] = true;
        members.push(_member);
    }
    
    function getMembers() public view returns (address[] memory) {
        return members;
    }

    function deposit(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        balance[msg.sender] += _amount;
    }

    function withdraw(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }


    function depositAmount() public payable onlyRegisteredMember{
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
    }
  
    function getBalance(address _user) public view returns(uint256)  {
        return balance[_user];
    }
}