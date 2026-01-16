// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank{

    //there should be a bank manager who has the certain peimissions
    //there should be an array for all members registered and a mapping whther they are registered or not
    //a mapping with there balance
    address public bankManager;
    address[] members;
    mapping (address => bool) public  registeredMembers;
    mapping (address => uint256) public balance;

    constructor(){
        bankManager = msg.sender;
        registeredMembers[msg.sender] = true;
        members.push(msg.sender);
    }

    modifier onlyBankManager(){
        require(msg.sender == bankManager,"Only BankManager can perform this action.");
        _;
    }

    modifier onlyRegisteredMember(){
        require(registeredMembers[msg.sender],"Member not registered.");
        _;
    }
    
    function addMember(address _member)public onlyBankManager{
        require(_member != address(0),"Invalid address.");
        require(_member != msg.sender,"BankManager is already a member.");
        require(!registeredMembers[_member],"Member already registerd.");
        registeredMembers[_member] = true;
        members.push(_member);
    }

    function getMembers() public view returns (address[] memory){
        return members;
    }

    //deposit in ether
    function depositAmountEther() public payable onlyRegisteredMember{
        require(msg.value > 0,"Invalid amount.");
        balance[msg.sender] = balance[msg.sender] + msg.value;
    }

    function withdrawAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0,"Invalid amount.");
        require(balance[msg.sender] >= _amount,"Insufficient balance.");
        balance[msg.sender] -= _amount;
        payable (msg.sender).transfer(_amount);
    }

    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0),"Invalid address.");
        return balance[_member];
    }

    function contractBalance() public view returns (uint256){
        return address(this).balance;//进阶：查看整个PiggyBank当前的 ETH 总额
    }

}
