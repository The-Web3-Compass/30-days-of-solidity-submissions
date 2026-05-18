/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {
    // State Variables
    address public bankManager;
    address[] public members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) public balance;

    // Set up the contract and register the creator
    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
        
        // BUG FIX: Ensure the manager is actually registered so they can deposit!
        registeredMembers[msg.sender] = true; 
    }

    // Modifiers
    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Member not registered");
        _;
    }
    
    // Admin function to add new friends to the piggy bank
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
    
    // The 'payable' keyword allows this function to receive real ETH
    function depositAmountEther() public payable onlyRegisteredMember {  
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
    }
    
    // BUG FIX: Actually send the ETH back to the user!
    function withdrawAmount(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        
        // SECURITY: Deduct the balance BEFORE sending the ETH (Reentrancy protection)
        balance[msg.sender] -= _amount;
        
        // Send the real ETH back to the caller's wallet
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "ETH transfer failed");
    }

    function getBalance(address _member) public view returns (uint256) {
        require(_member != address(0), "Invalid address");
        return balance[_member];
    } 
}
