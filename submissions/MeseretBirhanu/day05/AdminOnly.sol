// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AdminOnly{
    address public owner;
    uint64 public totalTreasure;
    uint64 public allowance;
    mapping(address => bool) public isAllowed;
    mapping (address => bool) public hasWithdrawn;

    constructor(){
        owner=msg.sender;
    }
    modifier onlyOwner(){
         require(owner == msg.sender, "only for owner!");
         _;
    }
    function addTreasure(uint64 _amount , uint64 _allow)public  onlyOwner{
            totalTreasure += _amount;
            allowance = _allow;

    }
     function approveUser(address _addr) public onlyOwner{
        isAllowed[_addr]=true;
     }
    function withdraw() public {
        require(msg.sender ==owner || isAllowed[msg.sender], "not allowed to withdraw");
        require(totalTreasure > 0, "we finished our treasure!");
        if(msg.sender ==owner){
            totalTreasure = 0;
        }else{
            require(!hasWithdrawn[msg.sender] , "u already withdrawed!");
            require(totalTreasure > allowance, "not enough treasure");
            totalTreasure -= allowance;
            hasWithdrawn[msg.sender]=true;
        }

    } 
    function resetWithdrawal(address _addr ) public onlyOwner{
          hasWithdrawn[_addr]=false;
    }
    function transferOwnership(address _addr) public onlyOwner{
        owner = _addr;
    }
}










