// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract PayBank {
    address public  bankmanager;

    address [] members;
    mapping (address => bool) public registeredMembers;

    mapping (address => uint256) balance;

    constructor ( ) {
       bankmanager = msg.sender;
       members.push(msg.sender);
    }

    //only bank manager

    modifier  onlyBankManger () {
        require(msg.sender == bankmanager, "Only Bank Manager can perform this action ");
        _;
    }

    //only registered memeber

    modifier onlyRegisteredMembers () {
       require (registeredMembers[msg.sender],"You are not registerd as a member"); 
       _;  
    }

    //adding new memeber

function addMemmbers (address _member) public onlyBankManger {
    require(_member !=  address (0) , "Invalid address");
    require(_member != msg.sender, "Bank manager is alredy a member");
    registeredMembers [_member] = true;
    members.push(_member);
}

function getMembers () public  view  returns (address [] memory){
    return  members;
}
function deposit ( uint256 _amount) public   onlyRegisteredMembers {
    require(_amount > 0 , "Invalid amount");
    balance[msg.sender] += _amount;
  }
//withdraw
function withdraw ( uint256 _amount) public onlyRegisteredMembers {
    require(_amount > 0, "Invalid amount");
    require(balance[msg.sender] >=_amount , "Insufficent balance message");
   balance [msg.sender] -= _amount;
}

function depositAmountEther() public  payable  onlyRegisteredMembers {
    require(msg.value > 0 , "Invalid Amount");
    balance[msg.sender] += msg.value;

}



}