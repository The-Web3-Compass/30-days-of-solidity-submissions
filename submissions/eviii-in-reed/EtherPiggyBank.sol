//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {
    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) balance;

    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
    }

    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Access Denied: Only the bank manager can perform this action.");
        _;
    }

    modifier onlyRegisteredMembers() {
        require(registeredMembers[msg.sender], "Access Denied: Member is not registered with the bank.");
        _;
    }

    function addMember(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address provided.");
        require(_member != msg.sender, "Cannot add yourself as a member.");
        require(!registeredMembers[_member],"Member is already registered with the bank.");
        members.push(_member);
        registeredMembers[_member] = true;
    }

    function getMember() public view returns(address[] memory) {
        return members;
    }

    function depositAmount(uint256 _amount) public onlyRegisteredMembers {
        require(_amount > 0, "Cannot accept amount less than 0.");
        balance[msg.sender] += _amount;
    }

    // Ether = 10^18 Wei
    function depositEther() public payable onlyRegisteredMembers {
        require(msg.value > 0, "Cannot accept amount less than 0.");
        balance[msg.sender] += msg.value;
    }

    function withdraw(uint256 _amount) public onlyRegisteredMembers {
        require(_amount > 0, "Cannot accept amount less than 0.");
        require(balance[msg.sender] >= _amount, "Insufficient balance.");
        balance[msg.sender] -= _amount;
    }

    function getBalance(address _member) public view returns (uint256) {
        require(_member != address(0), "Invalid address provided.");
        return balance[_member];
    }

}



// mamager: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// address1: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// address2: 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
// address3: 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
// address4: 0x617F2E2fD72FD9D5503197092aC168c91465E7f2
