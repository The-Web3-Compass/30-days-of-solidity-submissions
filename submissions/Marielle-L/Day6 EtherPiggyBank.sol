//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

constract EtherPiggyBank{

    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) balance;

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
    }

    modifier onlyBankManager(){
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Member not registered");
        _;
    }

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

/* deposit & withdraw amount
    function deposit(uint _amount) public onlyRegisteredMember{
        require(_amount>0,"Invalid amount");
        balance[msg.sender]+=_amount;
    }

    function withdraw(uint _amount) public onlyRegisteredMember{
        require(_amount>0,"Invalid amount");
        require(_amount<=balance[msg.sender],"Your balance is insufficient");
        balance[msg.sender]-=_amount;
    }
*/

    function depositAmountEther() public payable onlyRegisteredMember{  
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
   
    }
    

    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0), "Invalid address");
        return balance[_member];
    }
}
