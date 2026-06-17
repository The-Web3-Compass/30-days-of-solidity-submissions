// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

//  create functions that only the contract owner can call

contract AdminOnly{
    address public owner;
    uint256 public treasureAmount;
    mapping(address=>uint256) public withdrawalAllowance;
    mapping(address=>bool) public hasWithdrawn;


    constructor(){
        owner=msg.sender;

    }

    // Modifier is a special structure in solidity, which is attached to function declarations to execute specified logic before and/or after the function’s body.
    //Syntax:
    //modifier modifier_name(){
        // code to be executed before the function body
        //_;//A required placeholder indicating where the function’s body is inserted
        // code to be executed after the function body

    // }
    // Modifier for owner-only functions
    modifier onlyOwner(){
        require(msg.sender==owner,"Access denied:Only the owner can perform this action");
        _;
    }

    //Only the owner can add treasure
    function addTreasure(uint256 amount) public onlyOwner{
        treasureAmount+=amount;
    }

    // Only the owner can approve withdrawals
    // Owner set the amount of the retrieved treasure.
    function approveWithdrawal(address recipient,uint256 amount) public onlyOwner{
        require(amount<=treasureAmount,"Not enough treasure available");
        withdrawalAllowance[recipient]=amount;

    }


    // Anyone can attempt to withdraw, but only those with allowance will succeed.
    function withdrawTreasure(uint256 amount) public{
        // If sender of message if owner, it means that owner retrieve the treasure so the amount of treasure becomes lower.
        if(msg.sender==owner){
            require(amount<=treasureAmount,"Not enough treasury available for this action.");
            treasureAmount-=amount;
            return;// If the codes can run here in functions, it will immediately stop and exit the execution of function.
        }

        uint256 allowance=withdrawalAllowance[msg.sender];

        //Check if user has an allowance and hasn't withdrawn yet
        require(allowance>0,"You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender],"You have already withdrawn your treasure");
        require(allowance<=treasureAmount,"Not enough treasure in the chest");
        require(allowance>=amount,"Cannot withdraw more than you are allowed");//condition to check if user is withdrawing more than allowed


        hasWithdrawn[msg.sender]=true;
        treasureAmount-=allowance;
        withdrawalAllowance[msg.sender]=0;

    }

    // Only owner can reset someone's wiothdrawal status
    function resetWithdralStatus(address user) public onlyOwner{
        hasWithdrawn[user]=false;
    }

    //Only the owner can transfer ownership
    function transferOwnship(address newOwner) public onlyOwner{
        require(newOwner!=address(0),"Invalid address");//"address(0)" is invalid or non-effective address.
        owner=newOwner;

    }

    function getTreasureDetails() public view onlyOwner returns(uint256){
        return treasureAmount;
    }


}