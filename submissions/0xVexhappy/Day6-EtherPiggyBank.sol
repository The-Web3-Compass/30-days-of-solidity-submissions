// SPDX-License-Identifier: MIT
// @author 0xVexhappy

pragma solidity ^0.8.31;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract PiggyBank is ReentrancyGuard {
    address  public bankManager;
    mapping(address => uint256) public memberBalance;
    address[] members;
    mapping(address => bool) public registeredMembers;

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
    }

    modifier onlyBankManager(){
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember(){
        require(registeredMembers[msg.sender], "Member not registered");
        _;
    }

    function addMembers(address _member) public onlyBankManager{
        require(_member != address(0), "Invalid Address");
        require(_member != msg.sender, "Bank manager is already a member");
        require(!registeredMembers[_member], "Member already registered");
        
        registeredMembers[_member] = true;
        members.push(_member);
    }

    function getMembers() public view returns(address[] memory){
        return members;
    }


    function depositAmountEther() public payable onlyRegisteredMember{
        require(msg.value > 0, "Invalid amount");
        memberBalance[msg.sender] += msg.value;
    }

    function withdrawEther(uint256 _amount) public payable nonReentrant onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
        require(_amount <= memberBalance[msg.sender], "Insufficient balance");

        memberBalance[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");
    }
}

