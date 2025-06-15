//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

contract adminonly{
    address public owner;
    uint256 public treasureamount;
    mapping(address=>uint256) public withdrawalallowance;
    mapping(address=>bool) hasWithdrawn;

    constructor(){
        owner=msg.sender;

    }
    modifier onlyowner(){
        require (msg.sender==owner,"access denied: only the owner can perform this action.");
        _;
    }
    function addtreasure(uint256 amount)public onlyowner{
        treasureamount+=amount;
    }
    function approvewithdraw(address recipient, uint256 amount)public onlyowner{
        require(amount<=treasureamount,"insuffcient funds in the contract");
        withdrawalallowance[recipient]=amount;
    }
    function withdrawtreasure(uint256 amount)public {
       if (msg.sender==owner){
        require(amount<=treasureamount,"insufficient funds in the contract. ");
        treasureamount -=amount;
        return;
       }
       uint256 allowance=withdrawalallowance[msg.sender];
       require (allowance>0,"You don't have any treasure allowance.");
       require(!hasWithdrawn[msg.sender],"you have already withdrawn your treasure.");
       require(allowance<=treasureamount, "not enough treasure in the chest.");
       require(amount<=allowance, "not enough allowance for withdrawal.");



       hasWithdrawn[msg.sender]=true;
       treasureamount-=allowance;
       withdrawalallowance[msg.sender]=0;
    }
    function resetwithdrawalstatus(address user)public onlyowner{
        hasWithdrawn[user]=false;
        }
        function transferownership(address newowner)public onlyowner{


            require(newowner != address(0),"invalid new owner");
            owner=newowner;

        }
        function gettreasuredetails()public view onlyowner returns(uint256){

            return(treasureamount);
        }

}
