// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract EtherPiggyBank {
    // 银行管理员
    address public manager;
    // 银行成员
    address[] members;
    // 注册状态
    mapping(address => bool) public memberToRegistered;
    // 余额
    mapping(address => uint256) public memberToBalance;

    // 合约部署者为管理员
    constructor() {
        manager = msg.sender;
        members.push(msg.sender);
        memberToRegistered[msg.sender] = true;
        memberToBalance[msg.sender] = 0;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can perform this action");
        _;
    }

    modifier onlyMember() {
        require(memberToRegistered[msg.sender], "Member is not registered");
        _;
    }

    function addMember(address _member) public onlyManager {
        require(_member != address(0), "Invalid address");
        require(!memberToRegistered[_member], "Member is already registered");

        members.push(_member);
        memberToRegistered[_member] = true;
        memberToBalance[_member] = 0;
    }

    function getMembers() public view returns (address[] memory) {
        return members;
    }

    function depositAmount(uint256 _amount) public onlyMember {
        require(_amount > 0, "Invalid amount");
        memberToBalance[msg.sender] += _amount;
    }
    
    function depositInEther() public payable onlyMember {
        require(msg.value > 0, "Invalid amount");
        memberToBalance[msg.sender] += msg.value;
    }
    
    function withdrawAmount(uint256 _amount) public onlyMember {
        require(_amount > 0, "Invalid amount");
        require(memberToBalance[msg.sender] >= _amount, "Insufficient balance");

        memberToBalance[msg.sender] -= _amount;
    }

    function getBalance(address _member) public view returns (uint256) {
        require(_member != address(0), "Invalid address");
        return memberToBalance[_member];
    }
}