//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank{
    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) balances;
    mapping(address => uint256) limits;
    event Deposit(address indexed _from, uint256 _value);
    event Withdraw(address indexed _to, uint256 _value);

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
    }

    modifier bankManagerOnly {
        require(msg.sender == bankManager, "Only Bank Manager can perfrom this operation");
        _;
    }

    modifier registeredMemberOnly {
        require(registeredMembers[msg.sender], "Only a registered member can perform this operation" );
        _;
    }
  
    function addMembers(address _member, uint256 _limit) public bankManagerOnly{  
        require(_member != address(0), "Invalid address");
        require(!registeredMembers[_member], "Member already registered");
        members.push(_member);
        registeredMembers[_member] = true;
        limits[_member] = _limit;
    }

    function getMembers() public view returns(address[] memory){
        return members;
    }
    
    function depositAmountEther() public payable registeredMemberOnly{  
        require(msg.value > 0, "Invalid amount.");
        require(msg.value <= limits[msg.sender], "Amount should not exceed your deposit limit.");
        balances[msg.sender] += msg.value;   
    }
    
    function withdrawAmount(uint _amount) public registeredMemberOnly{
        require(_amount > 0, "Invalid amount.");
        require(_amount <= balances[msg.sender], "Withdrawal amount should not exceed your balance.");
        require(_amount <= limits[msg.sender], "Amount should not exceed your withdrawal limit.");
        balances[msg.sender] -= _amount;
    }

    function getBalance(address _member) public view returns (uint256) {
        require(msg.sender != address(0), "Invalid address.");
        return balances[_member];
    } 
}