// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank {
    address public bankManager;  //银行管理者
    address[] public members;   //成员列表
    mapping(address => bool) public registeredMembers; //成员->是否批准
    mapping(address => uint256) public balance; //成员->余额

    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
    }

    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registere);
    }
}