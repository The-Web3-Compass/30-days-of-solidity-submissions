// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract admitOnly{
    address public owner ;
    uint256 public treasureAmount;
    constructor(){
            owner=msg.sender;
    }

    modifier onlyOwner(){     //Reusable Access Control with a Modifier
        require(msg.sender==owner,"access denied:only owner can perform this action");
        _;    //The _ is where the rest of the function will be inserted if the check passes.
    }

    function addTreature(uint256 amount) public onlyOwner{   //这里后面插入onlyowner调用函数
      treasureAmount += amount;  
    }

    mapping(address=>uint256) public withdrawAllowance;
    
    function withdrawAllowal(address recipient ,uint256 amount) public onlyOwner {
            require(amount <= treasureAmount,"insufficent funds.");   //require逻辑是判断前一项，除非前一项满足，不然返回后一项的文字
            withdrawAllowance[recipient]=amount;
    }

    mapping (address=>bool) public hasWithDrawn;
    
    function withdrawTreasure (uint256 amount) public {
        if (msg.sender==owner){
            require(amount<=treasureAmount,"not enough money for this action." );
            treasureAmount-=amount;
            return;
        }

        uint256 allowance=withdrawalAllowance[msg.sender];
        require (allowence >0, "you have any treasure allowance." );
        require (!hasWithDrawn[msg.sender],"you had alreadly withdrawn your treasure.");
        require (allowance <= treasureAmount,"not enough treasure in the cheat.");       //If any of these fail, the function stops immediately.

        hasWithDrawn[msg.sender]=true;
        treasureAmount-=allowance;
        withdrawalAllowance[msg.sender]=0;
        msg.sender.transfer(allowance);
    }

    function resetstatus(address user) public onlyOwner{
      hasWithDrawn[user]=false;  
    }

    function transferOwner(address newOwner) public onlyOwner{
        require(address newOwner != address(0),"empty or invalid address.");
        owne r= newOwner;
    }
    function viewTreasureAmount() public view returns(uint256){
        return( treasureAmount);
    }







    }





}