// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract adminonly{
    address public owner;
    uint256 public treasureAmount; //宝藏总金额
    mapping (address => uint256) public withdrawalallowance;  //可提取金额
    mapping (address => bool) public hasWithdrawn;    //是否提取过

    //构造函数，只运行一次，谁部署合同，谁就是所有者
    constructor(){
        owner = msg.sender;
    }

    //修饰符modifier实现可复用访问控制
    modifier onlyOwner(){
        require(msg.sender == owner,"access denied:only the owner can perform this action");
        _;
    }

    //管理员加宝藏总金额
    function addTreasure(uint256 amount) public onlyOwner{
        treasureAmount += amount;
    }

    //管理者授予提取额度
    function approveWithdrawal(address recipient,uint256 amount) public onlyOwner{
        require(amount <= treasureAmount,"not enough treasury available for this action");
       withdrawalallowance[recipient] =amount;
    }

    //取钱
    function withdrawTreasure(uint256 amount) public{
        //管理员取
        if(msg.sender == owner){
            require(amount <= treasureAmount,"not enough treasury available for this action");
            treasureAmount -= amount;
            return ;
        }

        uint256 allowance = withdrawalallowance[msg.sender];

        //被授予人取
        require(allowance > 0,"you don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender],"you have already withdrawn your treasure");
        require(allowance <= treasureAmount,"not enough treasure in the chest");
        require(allowance >= amount,"cannot withdraw more than you are allowed" );

        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawalallowance[msg.sender] = 0;
    }
    //管理员重置是否已提取
    function restWithdrawalStatus(address user) public onlyOwner{
        hasWithdrawn[user] = false;
    }

    //管理者权限转移
    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0),"invalid address");
        owner = newOwner;
    }

    //读取宝藏总金额
    function getTreasureDetails() public view onlyOwner returns (uint256){
        return treasureAmount;
    }

}
