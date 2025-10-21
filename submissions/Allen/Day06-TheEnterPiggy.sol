// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

contract TheEnteerPiggy{

    address public bankManager;

    address[] members;

    mapping(address => bool) public registeredMembers;

    mapping(address => uint256) balances;

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
    }


    modifier onlyManager(){
        require(msg.sender == bankManager,"Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisterManager(){
        require(registeredMembers[msg.sender],"Only register member can perform this action");
        _;
    }

    function addMembers(address _member) public onlyManager {
        require(_member != address(0),"Invalid address");
        require(_member != bankManager,"Bank manager is already a member");
        require(!registeredMembers[_member], "Member alrady registered");
        registeredMembers[_member] = true;
        members.push(_member);

    }

    function getMembers() public view returns(address[] memory){
        return members;
    }

    function deposit(uint256 _amount) public onlyRegisterManager{
        require(_amount > 0,"Invalid amount");
        balances[msg.sender] += _amount;

    }

    function withdraw(uint256 _amount) public onlyRegisterManager(){
        require(_amount > 0,"Invalid amount");
        require(_amount <= balances[msg.sender],"You don't have enough money");
        balances[msg.sender] -= _amount;
    }

    // payable means this function is allowed to receive Ether.
    // Without it, any ETH sent would be rejected.
    function depositAmountEther() public payable onlyRegisterManager{
        require(msg.value > 0,"Invalid amount");
        balances[msg.sender] += msg.value;
    }


    function withdrawAmountEther() public payable onlyRegisterManager{
        require(msg.value > 0,"Invalid amount");
        require(msg.value <= balances[msg.sender],"You don't have enough money");
        balances[msg.sender] -= msg.value;
    }







}