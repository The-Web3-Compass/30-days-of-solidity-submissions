// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";

contract PiggyBank{
    address public Manager;
    address[] members;
    mapping(address => bool) isMember;
    uint256 balance;
    mapping(address => uint256) balances;
    string LastTx;

    constructor(){
        Manager = msg.sender;
        members.push(Manager);
        isMember[Manager] = true;
        balance = 0;
    }
    
    modifier OnlyManager(){
        require(msg.sender == Manager,"Only Manager can do");
        _;
    }

    modifier OnlyMembers(){
        require(isMember[msg.sender], "Only members can do");
        _;
    }

    function addMember(address _newMember) public OnlyManager{
        require(!isMember[_newMember],"Already registered");
        require(_newMember != address(0),"Invalid address");

        members.push(_newMember);
        isMember[_newMember] = true;
    }

    function deposit() external payable OnlyMembers{
        require(msg.value != 0, "Invalid value");
        balances[msg.sender] += msg.value;   //Bank receive money
        LastTx = string.concat(
            Strings.toHexString(uint160(msg.sender)), // address → 十六进制字符串
            " send ",
            Strings.toString(msg.value) ,              // uint256 → 十进制字符串
            " wei "
        );
        balance += msg.value;
    } 

    function withdraw(uint256 _amount) external OnlyMembers{
        require(_amount != 0, "Invalid value");
        balances[msg.sender] -= _amount;   //Bank return money
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "withdraw fail!!");

        LastTx = string.concat(
            Strings.toHexString(uint160(msg.sender)), // address → 十六进制字符串
            " take out ",
            Strings.toString(_amount),               // uint256 → 十进制字符串
            " wei "
        );
        balance -= _amount;
    } 
    
    function trackLastTx() public view returns(string memory){
        return LastTx;
    }

    function checkBalance() public view returns(uint256){
        return balance;
    }
}
