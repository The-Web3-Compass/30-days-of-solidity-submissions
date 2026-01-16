//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnterPiggyBank{
    
    //There should be a bank manager who has the permissions
    //There should be an array for members registered and a mapping whether they are registered or not
    //A mapping with their balances
    address public bankManager;
    address[] members;
    mapping(address => bool)public registeredMembers;
    mapping(address => uint256)balance;

    constructor(){
        bankManager = msg.sender;
        registeredMembers[msg.sender] = true;        
        members.push(msg.sender);
    }

    modifier onlyBankManager(){
        require(msg.sender == bankManager, "Only bankManager can perform this action");
        _;
    }

    modifier onlyRegisteredMembers(){
        require(registeredMembers[msg.sender],"Member not registered");
        _;
    }

    function addMember(address _member)public onlyBankManager{
        require(_member !=address(0),"Invalid address");
        require(_member !=msg.sender, "Bank Manager is already a member");
        require(!registeredMembers[_member],"Member already registered");
        registeredMembers[_member]=true;
        members.push(_member);
    }

    function getMembers()public view returns(address[]memory){
        return members;
    }

    //disposit amount
    function depositAmount(uint256 _amount)public onlyRegisteredMembers{
        require(_amount > 0, "Invalid amount");
        balance[msg.sender]= balance[msg.sender] +_amount;
    }

    //disposit in Ether
    function depositAmountEther()public payable onlyRegisteredMembers{
        require(msg.value > 0,"Invalid amount");
        balance[msg.sender] = balance[msg.sender] + msg.value;

    }

    function withdralAmount(uint256 _amount) public onlyRegisteredMembers{
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] = balance[msg.sender] -_amount;

    }

    function getBalance(address _member)public view returns (uint256){
        require(_member !=address(0), "Invalid address");
        return balance[_member];
    }
}