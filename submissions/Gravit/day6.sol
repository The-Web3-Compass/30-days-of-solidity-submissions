// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PiggyBank {
    address public bankManager;
    address[] public members;

    mapping(address => bool) public registeredMember;
    mapping(address => uint256) public balances;

    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
        registeredMember[msg.sender] = true;
    }

    modifier onlyManager() {
        require(msg.sender == bankManager, "You are not the Manager.");
        _;
    }

    modifier isRegisteredMember() {
        require(registeredMember[msg.sender], "You are not a registered member");
        _;
    }

    function addMembers(address _member) public onlyManager {
        require(_member != address(0), "Invalid Address");
        require(!registeredMember[_member], "Already a Member");
        members.push(_member);
        registeredMember[_member] = true;
    }

    function getAllMembers() public view returns (address[] memory) {
        return members;
    }

    function depositEther() public payable isRegisteredMember {
        require(msg.value > 0, "Invalid Amount");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public isRegisteredMember {
        require(balances[msg.sender] >= amount, "Insufficient Balance");
        require(amount > 0, "Invalid Amount");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function transfer(address to, uint256 amount) public isRegisteredMember {
        require(to != address(0), "Invalid address");
        require(registeredMember[to], "Recipient is not a registered member");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount > 0, "Amount must be greater than zero");

        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
