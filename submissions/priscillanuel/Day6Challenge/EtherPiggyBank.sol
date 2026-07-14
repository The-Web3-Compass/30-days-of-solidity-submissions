// SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EtherPiggyBank is ReentrancyGuard {


    address public bankOwner;// the owner of the Bank
    address[] members; // members of the bank
    mapping (address => bool) public registeredMembers; // registered members of the bank 
    mapping (address => uint) public MembersBalance;
    uint public nextInterestTime = block.timestamp + 5 minutes; // next interest time is every 5 minutes for testivg
    uint public interestRate = 3; // 3% interest rate
    uint public totalBalance; // total balance of the bank

 // ---------------- CONSTRUCTOR ----------------
    constructor () {
        bankOwner = msg.sender;
       members.push(msg.sender);
       registeredMembers[msg.sender] = true;

       ListOfGroupSavers.push(msg.sender);
       isGroupSaver[msg.sender] = true;

    }

// ---------------- MODIFIERS ----------------
modifier onlyBankOwner () {
   require (msg.sender ==bankOwner,"you're not the owner");
_;
}

modifier onlyRegisteredMembers () {
    require (registeredMembers[msg.sender], "members not registered");
    _;
}

// ----------------FUNCTIONS--------------------
function addMembers(address _newMember) onlyBankOwner public{
    require(_newMember != address(0), "invalid address");
    require(_newMember != msg.sender, "you can't add yourself");
    require(!registeredMembers[_newMember], "Member already registered");

    registeredMembers[_newMember] = true; 
    members.push(_newMember);
}

function checkMembers() public view returns (address[]memory) {
    return members;
}

function deposit() public payable onlyRegisteredMembers {
    require(msg.value > 0, "Amount must be greater than 0");
    MembersBalance[msg.sender] += msg.value;
}

function withdraw(uint _amount) public onlyRegisteredMembers nonReentrant{
    require(_amount > 0, "Amount must be greater than 0");
    require(MembersBalance[msg.sender]>=_amount, "Insufficient balance");
    MembersBalance[msg.sender] -= _amount;

    (bool success, ) = payable(msg.sender).call{value: _amount}("");
    require(success, "Transfer failed");
}

function interestCalculation() public view returns (uint) {
   require(MembersBalance[msg.sender] > 0, "No funds deposited");
    require (block.timestamp >= nextInterestTime, "Not yet time for interest calculation");
    uint interest = (MembersBalance[msg.sender] * interestRate) / 100;
    return interest;
}
// ----------------GROUPGOALs--------------------------------------------------

modifier onlyListOfGroupSavers() {
    require(isGroupSaver[msg.sender], "You are not a group saver");
    _;
}

 uint groupGoal = 0.5 ether;
 uint public  groupGoalBalance;
 mapping(address => uint) public groupGoalSavers; // address to the amount saved
 mapping (address=> bool) public isGroupSaver; //checks if an address saved
 address[] ListOfGroupSavers;

 function DepositGroupGoalSave() public payable onlyListOfGroupSavers {
    require(msg.value >= 0.0001 ether, "Minimum amount is 0.0001 ether");
    groupGoalSavers[msg.sender] += msg.value;
    groupGoalBalance += msg.value;
}
 

 function checkGroupGoalSaves() public view onlyListOfGroupSavers returns (uint) {
    require(groupGoalSavers[msg.sender] > 0,"you didn't save in this group");
    require(isGroupSaver[msg.sender],"you didn't save in this group");
    return groupGoalSavers[msg.sender];
 }

 function withdrawGroupGoalSave(uint _amount) public onlyListOfGroupSavers nonReentrant{
     require(groupGoalSavers[msg.sender] > 0,"you didn't save in this group");
     require(isGroupSaver[msg.sender],"you didn't save in this group");
     require(_amount <= groupGoalSavers[msg.sender],"you don't have enough balance");
    groupGoalSavers[msg.sender] -= _amount;
    groupGoalBalance -= _amount;

    (bool success, ) = payable(msg.sender).call{value: _amount}("");
    require(success, "Transfer failed");
 }


}