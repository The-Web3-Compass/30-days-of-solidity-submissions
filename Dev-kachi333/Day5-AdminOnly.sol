// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract AdminOnly {
    address public  owner;
    uint256 public  treasureAmount;

    constructor () {
        owner=msg.sender;
    }

    modifier onlyOwner () {
        require(msg.sender==owner," Acesss denied only if the owner can perform this action");
        _;
    }

    mapping  ( address=>uint256) public withdrawalAllowance;

    mapping (address=>bool) public hasWithdrawn;

    function addTreasure ( uint256 amount) public  onlyOwner {
        treasureAmount += amount ;
    }

    function approveWithdrawal ( address recipient , uint256 amount ) public  onlyOwner {
        require(amount<= treasureAmount," Not enough treasure availaible");
        withdrawalAllowance[ recipient]= amount;
    }

    function withdrawTreasure (uint256 amount) public {

        if (msg.sender ==owner) {
            require(amount <= treasureAmount, " Not emough treasury availiable for this action");
            treasureAmount-= amount;
            return ;
        }

        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance>0," You do not have any treasury allowace");
        require(!hasWithdrawn[msg.sender], "yo have already withdrawn your treasure");
        require(allowance <= treasureAmount, " Not enough  treasure in the chest");
        hasWithdrawn[msg.sender]=true;
        treasureAmount-=allowance;
        withdrawalAllowance [msg.sender]=0;
    }

    function resetwithdrawalStatus ( address user) public onlyOwner {
        hasWithdrawn[user]=false;
    }

    function transferOwnership (address newOwner) public  onlyOwner {
        require(newOwner != address (0)," Invalid address");
        owner=newOwner;
    }

    function  getTreasurerDetails () public  view  onlyOwner returns (uint256) {
        return  treasureAmount;
    }



}