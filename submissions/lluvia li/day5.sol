// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;


contract Adminonly{
    address public owner;
    uint256 public treasureAmount;
    mapping (address=> uint256) public withdrawalAllowance;
    mapping (address=> bool) public hasWithdrawn;

    constructor(){
        owner=msg.sender;
    }

    modifier Onlyowner (){
      require(msg.sender==owner, "Access denied: Only the owner can perform this action");
          _;
    }

    function addTreasure(uint256 amount) public Onlyowner{
        treasureAmount+= amount;
    }

    function approveWithdrawal(address recipient, uint256 amount) public Onlyowner{
       require(amount<= treasureAmount, "not enough treasure available");
       withdrawalAllowance[recipient]=amount;
    }

    function WithdrawalTreasure(uint256 amount) public {

        if (msg.sender==owner){

            require(amount<=treasureAmount, "Not enough treasury available for this action.");
            treasureAmount-=amount;
        }
       
       uint256 allowance =withdrawalAllowance[msg.sender];
       require(allowance>0, "You don't have any treasure allowance");
       require(!hasWithdrawn[msg.sender],"You have already withdrawn your treasure");
       require(allowance<= treasureAmount,"Not enough treasure in the chest");
       require(amount<= allowance,"Cannot withdraw more than you are allowed");

       hasWithdrawn[msg.sender]=true;
       treasureAmount-=amount;
       withdrawalAllowance[msg.sender]=0;

    }

    function resetWithdrawalStatus(address user) public Onlyowner{

        hasWithdrawn[user]=false;
    }
   
    function transferOwnership(address NewOwner)public Onlyowner{

        require(NewOwner!= address(0),"Invalidate address");
        owner=NewOwner;
    }

    function getTreasureDetails() public view Onlyowner returns (uint256){
        return treasureAmount;
    }


}
