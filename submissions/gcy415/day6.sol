// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank{
    address public bankManager;
    address[] members;
    mapping(address=> bool) public registeredMembers;
    mapping(address => uint256) balance;
    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
        registeredMembers[msg.sender] = true;
    }
    modifier onlyBankManager(){
        require(msg.sender == bankManager,"only bank manager can perform this action");
        _;
    }
    modifier onlyRegisteredMember(){
        require(registeredMembers[msg.sender],"member not registered.");
        _;
        }
    function addMembers(address _member) public onlyBankManager{
        require(_member != address(0),"Invalid address");
        require(_member != msg.sender, "Bank Manager is already a member");
        require(!registeredMembers[_member],"Already registered!");
        registeredMembers[_member] = true;
        members.push(_member);
    }
    function getMembers() public view returns (address[] memory){
        return members;
    }
    //function deposit(uint256 _amount) public onlyRegisteredMember{
    //    require(_amount > 0, "Invalid Deposit Amount");
    //    balance[msg.sender] += _amount;
    //}

    function withdraw(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0,"Withdraw amount is zero or less");
        require(balance[msg.sender] >= _amount, "Insufficient Balance!");
        balance[msg.sender] -= _amount;
    }

    function depositEther() public payable onlyRegisteredMember{
        require(msg.value > 0, "Invalid  Amount");
        balance[msg.sender] += msg.value;
    }
    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0),"Invalid address");
        return balance[_member];
    }



}
