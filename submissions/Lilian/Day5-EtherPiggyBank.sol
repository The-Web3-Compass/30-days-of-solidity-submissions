// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank{
    address public bankManager;
    address[]members;
    mapping(address=>bool)public registeredMenbers;
    mapping (address=>uint256)balance;

    constructor(){
        bankManager=msg.sender;
        members.push(msg.sender);
    }

    modifier onlybankmanger(){
        require(msg.sender ==bankManager,"only bank manager can perform this action");
        -
    }

    modifier onlyregistermembers(){
        require(registeredMenbers[msg.sender],"member not registered");
        -
    }
    function addmembers(address_members)public onlybankManager{
        require(_member !=address(0),"invalid address");
        require(_member !=msg.sender,"bank manager is already a member");
        require(!registeredMenbers[members],"member already registered");
        registeredMenbers[_member]=true;
        members.push(_member);
    }
    function getmembers ()public view returns (address[]memory){
        returns members;
    }
    function depoistAmountEther()public payable only registermembers{
        require(msg.value>0,"Invalid Amount");
        balance[msg.sender]=balance [msg.sender]+msg.value;
    }
    function withdrawAmount(uint256_amount)public onlyregistermembers{
        require(_amount>0,"Invalid Amount");
        require(balance[msg.sender]>=amount, "Insufficence balance");
        balance[msg.sender]=balance[msg.sender]-_amount;
    }
    function getbalance(address_member)public view returns (uint256){
        require(_member!=address(0),"Invalid address");
        return balance(_member)
    }
}
