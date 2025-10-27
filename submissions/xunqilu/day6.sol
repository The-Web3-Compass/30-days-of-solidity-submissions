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
        require(msg.sender == bankManager, "You are not allowed to do it");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Member not found");
        _;
    }
  
    function addMembers(address _member)public onlyBankManager{
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Your are already registered");
        require(!registeredMembers[_member], "Member already registered");
        registeredMembers[_member] = true;
        members.push(_member);
    }

    function getMembers() public view returns(address[] memory){ // when we defined a array, we need to add memory
        return members;
    }
    
    //this piece code won't really change the ether balance
    function deposit(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
        balance[msg.sender] += _amount;
    }


    //deposit in Ether using payable and msg.value
    function depositEther() public payable onlyRegisteredMember{  
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
   
    }
    
    //1 Ether = 10^18 Wei

    //didn't withdraw real ether from the address
    // only modified the mapping inside the contract
    function withdrawAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
   
    }

    // METHOD 1 - withdraw the real ether 
    //amount unit in Wei
    function withdrawEther1(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");

        // update balance first
        balance[msg.sender] -= _amount;
        // transfer
        payable(msg.sender).transfer(_amount);
}


    // METHOD - 2 withdraw the real ether 
    //amount unit in Wei
    // chatgpt said it's safer way and no gas limit， where method 1 has 2300 gas limit？
    //still trying to understand it
    function withdrawEther2(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");

        balance[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");
    }


    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0), "Invalid address");
        return balance[_member];
    } 
}