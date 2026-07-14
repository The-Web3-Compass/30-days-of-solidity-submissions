// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract AdminOnly{
    address public owner;

    constructor( ) {
        owner=msg.sender;
    }
        modifier onlyOwner(){
            require(msg.sender==owner,"Access denied: Only the owner can perform this action");
            _;
        }
        uint256 public treasureAmount;
        function addTreasure(uint256 amount) public onlyOwner{
            treasureAmount += amount;
        }

        mapping (address=>uint256) public withdrawalAllowance;
        function approveWithdrawal(address recipient, uint256 amount)public onlyOwner{
            require(amount<=treasureAmount,"Not enough treasure available");
            withdrawalAllowance[recipient]=amount;
        }

        mapping (address=>bool) public hasWithdrawn;
        function withdrawTreasure(uint256 amount) public {
            //拥有者取宝
            if(msg.sender==owner){
                require(amount<=treasureAmount,"Not enough treasury available for this action.");
                treasureAmount -=amount;
                return ;
            }
            //普通用户取宝
            uint256 allowance =withdrawalAllowance[msg.sender];
            require(allowance>=amount,"You are not allowed to withdraw this amount of treasure");
            require(!hasWithdrawn[msg.sender],"You have already withdrawn your treasure");
            withdrawalAllowance[msg.sender]=0;
            hasWithdrawn[msg.sender]=true;

            treasureAmount -=amount;


        }

        //重置提取状态
        function reset(address user) public onlyOwner{
            hasWithdrawn[user]=false;
        }

        //转移所有权
        function transferOwnership(address newOwner) public onlyOwner{
            require(newOwner!=address(0),"Invaild address");
            owner=newOwner;
        }

        //查看信息
        function check() public view onlyOwner returns(uint256){
            return treasureAmount;
        }
    
}