// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
contract Adminonly{
    address owner;
    uint public treasure=0;
    mapping (address=>uint)userAllocation;
    constructor(){
        owner=msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can call this function");
        _;
    }
    function addTreasure(uint amt) onlyOwner public{
        treasure+=amt;
    }
    function allocateLimit(address _addr,uint limit)onlyOwner public{
        require(userAllocation[_addr]==0,"Already allocated");
        userAllocation[_addr]=limit;
    }
    function withdrawTreasure(uint amt)onlyOwner public {
        require(amt>0,"Amount is 0");
        require(amt<treasure,"Greater then Treasure value");
        if(msg.sender==owner){
            treasure-=amt;
            return ;
        }else{
            require(userAllocation[msg.sender]!=0,"You have No acess");
            require(userAllocation[msg.sender]>=amt,"Amount greater than your acess");
            treasure-=amt;
            userAllocation[msg.sender]-=amt;
        }
    } 
}