// SPDX-License-Identifier:MIN
pragma solidity ^0.8.0;

contract EtherPiggyBank{
    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMember;
    mapping(address => uint256) balance;

    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
    } 

    modifier onlyBankManager() {
        require(msg.sender == bankManager, "only bankmanager can perform this action.");
        _;
    }
    modifier onlyRegisteredMember(){
        require(registeredMember[msg.sender], "only registered member can perform this action.");
        _;
    }

    function addMembers(address _member) public onlyBankManager(){

        require(_member != address(0), "invalid address.");
        require(_member != msg.sender, "bank manager is already the member.");
        require(!registeredMember[_member], "member is already registered.");

        registeredMember[_member] = true;
        members.push(_member);

    }
    
    function getMembers() public view returns(address[] memory) {
        return members;
    }

    function depositAmount(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "invalid amount.");
        balance[msg.sender] += _amount;
    }

    function withdrawAmount(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "invalid amount.");
        require(_amount <= balance[msg.sender], "insufficient funds.");
        balance[msg.sender] -= _amount;
    }

    //交易币 payable msg.value
    function depositEther() public payable onlyRegisteredMember {
        require(msg.value > 0, "invalid amount.");
        balance[msg.sender] += msg.value;
    }

}