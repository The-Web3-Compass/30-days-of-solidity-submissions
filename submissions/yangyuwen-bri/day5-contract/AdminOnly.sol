// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract AdminOnly{
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public haswithdrawn;

    constructor(){
        owner = msg.sender;
    }

    // 创建限制条件，在其他function可作为前置条件调用
    modifier onlyOwner(){
        
        require(msg.sender == owner, "Access denied: Only the owner can perform this action.");
        _;

    }

    function addTreasure(uint256 amount) public onlyOwner{
        treasureAmount += amount;
    }

    //批准特定用户提现
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner{
        require(amount <= treasureAmount, "insufficient funds in the contract.");
        withdrawalAllowance[recipient] = amount;
    }

    //执行提现行为：无前置条件
    function withdrawTreasure(uint256 amount) public{
        if(msg.sender == owner){
            require(amount <= treasureAmount, "insufficient fund in the contract.");
            treasureAmount -= amount;
            return;
        }

        uint256 allowance = withdrawalAllowance[msg.sender];

        // 我的逻辑：想用if else函数但是失败了，小机器人解答说return必须返回值而不是一串字符。
        //if(allowance > 0 && allowance >= amount){
            //treasureAmount -= allowance;
            //haswithdrawn[msg.sender] = true;
            //withdrawalAllowance[msg.sender] = 0;
        //} else return "you cant withraw money";

        require(allowance > 0, "you dont have any treasure allowance.");
        require(!haswithdrawn[msg.sender], "you have already withdrawn your treasure.");
        require(allowance <= treasureAmount, "not enough treasure in the chest.");
        require(allowance >= amount, "you dont have enough allowance to withdraw.");

        haswithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] = 0;
    }

    function resetWithdrawalStatus(address user) public onlyOwner{
        haswithdrawn[user] = false;
    }
    
    //转移所有权
    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0), "invalid new owner.");
        owner = newOwner;
    }
    


}

