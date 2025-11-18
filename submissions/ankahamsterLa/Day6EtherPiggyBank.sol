//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

// Design a system where users can join the group if approved, deposit savings, check their balance and even can withdraw when users need it.
contract EtherPiggyBank{

    //there should be a bank manager who has the certain permissions
    //there shoule be an array for all members registered and a mapping whether they are registered or not
    //a mapping with there balances

    address public bankManager;
    address[] members;
    mapping(address=>bool) public registeredMembers;
    mapping(address=>uint256) balance;

    constructor(){
        bankManager=msg.sender;
        members.push(msg.sender);
    }

    modifier onlyBankManager(){
        require(msg.sender==bankManager,"Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember(){
        require(registeredMembers[msg.sender],"Member not registered");
        _;
    }

    function addMembers(address _member) public onlyBankManager{
        require(_member!=address(0),"Invalid address");
        require(_member!=msg.sender,"Bank Manager is already a member");
        require(!registeredMembers[_member],"Member already registered");
        
        // If the member is not registered or bankmanager, add to the members array.
        registeredMembers[_member]=true;
        members.push(_member);
    }

    function getMembers() public view returns(address[] memory){
        return members;
    }

    // // deposit amount
    // function depositAmount(uint256 _amount) public onlyRegisteredMember{
    //     require(_amount>0,"Invalid amount");
    //     balance[msg.sender]+=_amount;
    // }

    // deposit in Ether
    //"Payable" keyword is used for declaration of functions which indicates that the funcitons can receive ether or other tokens.
    //"msg.value" is the amount of ETH in transaction. When executed, ETH could be stored in the contract and becomes balance of members.
    function depositAmountEther() public payable onlyRegisteredMember{
        require(msg.value>0,"Invalid amount");
        balance[msg.sender]=balance[msg.sender]+msg.value;
    }

    function withdrawAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount>0,"Invalid amount");
        require(balance[msg.sender]>=_amount,"Insufficient balance");
        balance[msg.sender]=balance[msg.sender]-_amount;
    }

    function getBalance(address _member) public view returns(uint256){
        require(_member!=address(0),"Invalid address");
        return balance[_member];
    }

}