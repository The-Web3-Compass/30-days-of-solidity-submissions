// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank {

    // The bank manager has exclusive permissions to manage members
    address public bankManager;

    // Array to store all registered members
    address[] public allMembers;

    // Mapping to check if an address is a registered member
    mapping(address => bool) public isRegistered;

    // Mapping to track the Ether balance of each member
    mapping(address => uint256) private memberBalances;

    // Set the deployer as the initial bank manager and member
    constructor() {
        bankManager = msg.sender;
        allMembers.push(msg.sender);
        isRegistered[msg.sender] = true;
    }

    // Restrict access to only the bank manager
    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    // Restrict access to only registered members
    modifier onlyMember() {
        require(isRegistered[msg.sender], "Member not registered");
        _;
    }

    // Allows the bank manager to add a new member
    function addMember(address _newMember) public onlyBankManager {
        require(_newMember != address(0), "Invalid address");
        require(_newMember != msg.sender, "Bank Manager is already a member");
        require(!isRegistered[_newMember], "Member already registered");

        isRegistered[_newMember] = true;
        allMembers.push(_newMember);
    }

    // Returns the list of all registered members
    function getAllMembers() public view returns(address[] memory) {
        return allMembers;
    }

    // Allows registered members to deposit Ether into their balance
    function depositEther() public payable onlyMember {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        memberBalances[msg.sender] += msg.value;
    }

    // Allows registered members to withdraw a specific amount
    function withdrawEther(uint256 _amount) public onlyMember {
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(memberBalances[msg.sender] >= _amount, "Insufficient balance");

        memberBalances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    // Returns the Ether balance of a specific member
    function getBalance(address _member) public view returns (uint256) {
        require(_member != address(0), "Invalid address");
        return memberBalances[_member];
    }
}