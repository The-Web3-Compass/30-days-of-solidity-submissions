// SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

contract AdminOnly {

    address public owner; //宝藏所有者
    uint256 public treasureAmount;//宝藏价值
    mapping(address => uint256) public withdrawalAllowance;//允许他人提取多少钱
    mapping(address => bool) public hasWithdrawn; // 用户是否已经提取过宝藏

    constructor(){
        owner = msg.sender;
    }
    // 定义可重用访问权限
    modifier onlyOwner(){
        require(msg.sender == owner,"Access denied:Only the owner can perform this action");
        _;
    }

    // 添加宝藏的价值
    function addTreasure(uint256 amount) public onlyOwner{
        treasureAmount += amount;
    }

    // 批准他人提款
    function approveWithdrawal(address recipient,uint256 amount) public onlyOwner{
        require(amount<=treasureAmount,"Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
    }

    //提取宝藏
    function withdrawTreasure(uint256 amount) public {
        // 所有者自己提取宝箱中的宝物
        if(msg.sender==owner){
            require(amount<=treasureAmount,"Not enough treasury available for this action.");
            treasureAmount-=amount;
            return ;
        }
        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance>0,"You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender],"you have already withdrawn your treasure");
        require(allowance<=treasureAmount,"Not enough treasure in the chest");

        hasWithdrawn[msg.sender] = true;
        treasureAmount -= amount;
        withdrawalAllowance[msg.sender] = 0;
    }

    // 重置用户提取状态
    function resetWithdrawalStatus(address user, uint256 amount) public onlyOwner{
        hasWithdrawn[user] = false;
        withdrawalAllowance[user] = amount;
    }

    //所有权转让
    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner!=address(0),"Invalid address");
        require(newOwner != owner, "The current user is already the owner");
        owner = newOwner;
    }

    // 查看宝藏
    function getTreasureDetails() public view onlyOwner returns (uint256){
        return treasureAmount;
    }
    
}