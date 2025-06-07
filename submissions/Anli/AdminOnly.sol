//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract adminOnly{
    /*
    1.  定义·owner，treasure数目，每个人的限额
    2. 判定是不是owner的modifier
    3. 增加treasure
    4. 批准withdrawlAllowance
    5. 提取treasure （1）owner （2）其他用户：是否具备allwance？是否已经提取过？

    */
    address owner;
    uint256 public treasureAmount;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require (msg.sender == owner, "Access denied: Only the owner can perform his action.");//==是比较运算符；=是赋值运算符
        _; //表示检查通过时插入函数其余部分的内容
    }

    function addTreasure(uint256 _amount) public onlyOwner{ //modifier using
        treasureAmount += _amount;   
    }

    mapping(address => uint256) public withdrawalAllowance;
    function approveWithdraw (address recipient, uint256 amount) public onlyOwner{
        require (amount <= treasureAmount, "Not enough treasure available.");
        withdrawalAllowance[recipient] = amount; //mapping is not array!!!
    }

    mapping(address => bool) hasWithdrawn;//设置这个验证的意义是？
    function withdraw(uint256 amount) public {

        if (msg.sender == owner)
        {
            require(amount <= treasureAmount, "Not ehough treasure avaiable for this action.");
            treasureAmount -= amount;
            return; //立即退出函数，不再执行后续的代码
        }

        uint256 allowance = withdrawalAllowance[msg.sender];//定义这个值属于可读性优化
        require(allowance > 0, "You don't have any treasure allowance.");
        require(!hasWithdrawn[msg.sender],"You have already withdrawn your treasure.");
        require(allowance <= treasureAmount, "Not enough treasure in the chest.");
        
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] = 0;
    }

    function resetWithdrawlStatus(address user) public onlyOwner{ //withdrawalAllowance 的重置应该由 approveWithdraw() 来控制
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0), "Invalid address.");//newOwner != address(0) 检查这个地址不是一个空地址，防止onlyOwner再也无法执行
        owner = newOwner;
    }
}