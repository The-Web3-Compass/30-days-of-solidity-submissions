//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
    
contract EtherPiggyBank {

    address public BankManager;
    address[] Members;
    mapping(address => bool) public RegisteredMembers;
    mapping(address => uint256) balance;

    constructor(){
        BankManager = msg.sender;
        Members.push(msg.sender);
        
    }

    modifier OnlyBankManager(){
        require(BankManager == msg.sender, "Only bank manager can perform this action");
        _;

    }

    modifier OnlyRegisteredMember(){
        require(RegisteredMembers[msg.sender], "Member is not registered");
        _;

    }


    function AddMembers(address _Member_) public OnlyBankManager{
        require (_Member_ != address(0), "Invalid address");
        require (_Member_ != msg.sender, "Bank manager is already a member");
        require (!RegisteredMembers[_Member_], "Member is already registered");
        RegisteredMembers[_Member_] = true;
        Members.push(_Member_);

    }

    function GetMembers() public view returns(address[] memory){
        return Members;

    }

    function DepositAmount(uint256 _Amount_) public OnlyRegisteredMember{
        require(_Amount_ > 0, "Invalid amount");
        balance[msg.sender] += _Amount_;

    }

    function DepositEther() public payable OnlyRegisteredMember{
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] = balance[msg.sender] + msg.value;

    }

    function Withdraw(uint256 _Amount_) public OnlyRegisteredMember{
        require (_Amount_ > 0, "Invalid amount");
        require(balance[msg.sender] >= _Amount_, "Insufficient funds");
        balance[msg.sender] -= _Amount_;

    }

    function GetBalance(address _Member_) public view returns(uint256){
        require(_Member_ != address(0), "Invalid address");
        return balance[_Member_];

    }


}

