// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {

    address public immutable bankManager;
    address[] private members;

    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) private balances;

    constructor() {
        bankManager = msg.sender;
        registeredMembers[msg.sender] = true; // mark manager as member
        members.push(msg.sender);
    }

    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Not a registered member");
        _;
    }

    function addMember(address _member) external onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(!registeredMembers[_member], "Already registered");

        registeredMembers[_member] = true;
        members.push(_member);
    }

    function getMembers() external view returns (address[] memory) {
        return members;
    }

    receive() external payable {
        // fallback deposit to sender if they’re a registered member
        require(registeredMembers[msg.sender], "Not a registered member");
        balances[msg.sender] += msg.value;
    }

    function deposit() external payable onlyRegisteredMember {
        require(_amount > 0, "Withdraw must be > 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function getBalance(address _member) external view returns (uint256) {
        return balances[_member];
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
