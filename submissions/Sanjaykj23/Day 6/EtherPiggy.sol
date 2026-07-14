// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
contract Bank{
    mapping (address=>uint)Balances;
    mapping (address=>bool) Users;
    address owner;
    constructor(){
        owner=msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender==owner,"Not an Owner!");
        _;
    }
    function addUser(address _addr)onlyOwner public  {
        require(Users[_addr]==false,"User Already Exist!");
        Users[_addr]=true;
    }
    function deposit(address _adr,uint amt) public {
        require(Users[_adr]==true,"User not exist!");
        //require(Balances[_adr]>=amt,"No amount");
        Balances[_adr]+=amt;
    }
    function withdraw(address _adr,uint amt)public {
        require(Users[_adr]==true,"User not exist!");
        require(Balances[_adr]<amt,"No amount");
        Balances[_adr]-=amt;
    }
}