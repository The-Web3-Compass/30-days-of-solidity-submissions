// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;
/*
    Let's make a digital piggy bank! 
    Users can deposit and withdraw Ether (the cryptocurrency). 
    You'll learn how to manage balances (using `address` to identify users) and track 
    who sent Ether (using `msg.sender`). 
    It's like a simple bank account on the blockchain, demonstrating how to handle Ether and user addresses.
*/

contract EtherPiggyBank{

    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMember;
    mapping(address => uint256) balance;

    constructor(){
        bankManager = msg.sender;
        balance[msg.sender] = 0;
    }

    modifier onlyBankManager(){
        require (bankManager == msg.sender, "Only bank manager can perform this action");
        _;
    }
    modifier onlyRegisteredMember(){
        require (registeredMember[msg.sender], "Member is not registered");
        _;
    }

    function addMembers(address _member ) public onlyBankManager{
        require(_member != address(0), "Invalid address" );
        require(_member != msg.sender, "Bank manager is already a member");
        require(!registeredMember[_member], "Member is already registered");
        registeredMember[_member] = true;
        members.push(_member);
    }

    function getMembers () public onlyBankManager view returns(address[] memory){
        return members;       
    }

    function getBalanceManager (address _account) public onlyRegisteredMember view returns (uint256){
        return balance[_account];
    }

    function getBalanceUser() public view returns (uint256){
        return balance[msg.sender];
    }

    function depositAmount(uint256 _amount, address receiver ) public onlyRegisteredMember{
        require(_amount > 0, "Amount is invalid");
        balance[receiver] += _amount;
        balance[msg.sender] -= _amount;
    }

    function depositEther () public payable onlyRegisteredMember{
        require(msg.value > 0, "Invalid amount!");
        balance[msg.sender] += msg.value;
    }

    function withraw (uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount!");
        require(balance[msg.sender] >= 0, "Insuficient amount");
        balance[msg.sender] -= _amount;
    }
}