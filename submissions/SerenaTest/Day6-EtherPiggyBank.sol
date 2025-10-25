//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank{

    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) balance;

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);        //直接将银行经理添加为会员
    }

//银行经理
    modifier onlyBankManager(){
        require(msg.sender == bankManager, "Access denied: Only bank manager can perform this action");
        _;
    }

//会员
    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "You dont registered");
        _;
    }

//注册会员
    function addMembers(address _member)public onlyBankManager{
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Bank Manager is already a member");
        require(!registeredMembers[_member], "Member already registered");
        registeredMembers[_member] = true;
        members.push(_member);
    }

    function getMembers() public view returns(address[] memory){
        return members;
    }

    //存款(存入以太币)
    function depositAmountEther() public payable onlyRegisteredMember{  
        require(msg.value > 0, "amount should > 0");
        balance[msg.sender] = balance[msg.sender]+msg.value;
   
    }
    
    //取款
    function withdrawAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "amount should > 0");
        require(balance[msg.sender] >= _amount, "Your balance is not enough");
        balance[msg.sender] = balance[msg.sender]-_amount;
   
    }

    //查询存款
    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0), "Invalid address");
        return balance[_member];
    } 
}