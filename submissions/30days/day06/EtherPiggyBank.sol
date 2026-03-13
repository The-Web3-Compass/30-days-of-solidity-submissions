// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PiggyBank{

    address public bankManager;

    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) public balance;

    constructor(){
        bankManager = msg.sender;
        members.push(bankManager);
    }
    modifier onlyBankManager(){
        require(msg.sender == bankManager,"Only bank manager can perform this.");
        _;
    }
    modifier onlyRegisteredMember(){
        require(registeredMembers[msg.sender],"Not registered.");
        _;
    }
    function addMembers(address _member) public onlyBankManager{
        require(_member != address(0),"Invalid address.");
        require(_member != bankManager,"Bank manager is member.");
        require(!registeredMembers[_member],"member alredy registered.");
        registeredMembers[_member] = true;
        members.push(_member);
    }
    function getMembers() public view returns(address[] memory){
        return members;
    }
    function depositeAmount() public payable onlyRegisteredMember{
        require(msg.value > 0,"Invalid amount.");
        balance[msg.sender] += msg.value;

    }

    function withdraw(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0,"Invalid amount.");
        require(balance[msg.sender] >= _amount,"Insufficient balance.");
        balance[msg.sender] -= _amount;

        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer is failed");
    }

}