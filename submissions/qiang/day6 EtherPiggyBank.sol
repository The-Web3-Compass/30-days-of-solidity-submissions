// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank{

    address public bankManager;
    address [] members;
    mapping (address => bool) public registeredMembers;
    mapping (address => uint256) balance;

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
    }

    modifier onlyBankManager(){
        require(bankManager ==msg.sender,"Only bank manager can perform this action" );
        _;
    }

    modifier onlyRegisteredMember(){
        require(registeredMembers[msg.sender],"Member is not registered");
        _;
    }

    function addMembers(address _member) public onlyBankManager{
        require(_member != address(0),"Invalid address");
        require(_member != msg.sender,"Bank Manger is already a member");
        require(!registeredMembers[_member],"member is already registered");
        registeredMembers[_member] = true;
        members.push(_member);
    }

    function getMembers() public view returns(address[] memory){
        return members;
    }

    function depositAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0,"Invalid amount");
        balance[msg.sender] += _amount;
    }

        function depositEther() public onlyRegisteredMember payable {
        require(msg.value > 0,"Invalid amount");
        balance[msg.sender] += msg.value;
    }

    function withdraw(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0,"Invalid amount");
        require(balance[msg.sender] >= _amount,"Insufficient funds");
        balance[msg.sender] -= _amount;
    }

    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0),"Invalid address");
        return balance[_member];
    }


}
