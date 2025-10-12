// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract etherPiggyBank{
    address public bankManager;
    address[] members;
    mapping (address => bool)public registerMembers;
    mapping (address => uint256)balance;

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
        registerMembers[msg.sender]=true;
    }

    modifier onlyManager(){
        require (msg.sender == bankManager,"You are not the manager");
        _;
    }

    modifier onlyRegisteredMember(){
        require (registerMembers[msg.sender],"You are not a registered member sorry :(");
        _;
    }

    function addMember(address _member) public onlyManager{
        require (_member != address(0),"Invalid address!");
        require (_member != msg.sender,"Remember you are the manager");
        require (!registerMembers[_member],"Member is already registered");
        registerMembers[_member] = true;

    }

    function getMembers() public view returns(address[] memory){
        return members;
    }

    function depositAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0,"Invalid amount");
        balance[msg.sender] += _amount;
    }

    function withdraw(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0,"Invalid amount");
        require(balance[msg.sender] >= _amount,"Insufficient balance");
        balance[msg.sender] -= _amount;
    }

    function depositEther() public payable onlyRegisteredMember{
        require(msg.value > 0,"Invalid amount");
        balance[msg.sender] += msg.value;
    }

    function getBalance(address _member) public view onlyRegisteredMember returns(uint256){
        require(_member != address(0),"Invalid address!");
        return balance[_member];
    }










}