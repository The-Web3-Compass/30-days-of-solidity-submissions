//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;     //记录宝藏的总数
    mapping(address => uint256) public withdrawalAllowance;     //名字是...的映射表，地址对应数字
    mapping(address => bool) public hasWithdrawn;     //名字是...的映射表，每个地址对应一个布尔值（T or F）

    constructor() {     //构造函数，只能在部署时运行一次
        owner = msg.sender;     //msg.sender(当前调用合约的人）保存到owner里，谁创建的合约，谁就是主人
    }

//只允许管理员执行的检查规则
modifier onlyOwner() {     //定义名字叫...的修饰器，用于复用权限检查器
    require(msg.sender == owner, "Access denied: Only the owner can perform this action");     //检查当前调用的人是不是owner，如果不是就停止执行并报错“ ”   require（条件， “错误信息”）
    _;     //特殊符号，表示“执行被修饰的函数”，即继续执行原函数
}

//注释只用拥有者才能“加宝藏”
function addTreasure(uint256 amount) public onlyOwner {     //定义只有管理员才能执行的增加的一个宝藏数量
    treasureAmount += amount;     //在原来的基础上增加一定数量
}

//注释只用拥有者能批准可以取宝藏
function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {     //定义函数批准提取，管理员输入接受者的地址，能提取多少
    require (amount <= treasureAmount, "Not enough treasure available");     //检查批准的数量不能比宝藏总数多，否则退回并弹出“”
    withdrawalAllowance[recipient] = amount;     //给接受者设置他的提取额度    
}

//任何人都能试着去宝藏，但只有批准过的人才能成功
function withdrawTreasure(uint256 amount) public {     //定义一个用户取宝藏数量的函数
    if(msg.sender == owner){     //如果当前调用的人是owner，则执行下面的逻辑
        require(amount <= treasureAmount, "Not enough treasure available for this action");     //检查管理员想拿的宝藏是否超过总数，超过则退回并弹出“”
        treasureAmount-= amount;     //从宝藏总数减掉对应的数量

        return;     //执行完就直接结束，不再继续往下执行
    }
     //如果不是管理员，则执行下面的逻辑
    uint256 allowance = withdrawalAllowance[msg.sender];       //取出当前调用者的“批准额度”存到本地变量里

    require(allowance > 0, "You don't have any treasure allowance");     //检查调用者有没有被批准过额度，如果是0则表示没资格，退回并弹出“”
    require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");     //检查这个人以前是不是已经取过了，如果取过则退回并弹出“”     
    require(allowance <= treasureAmount, "Not  enough treasure in the chest");     //检查宝藏够不够发，不够则退回并弹出“”
    require(allowance >= amount, "Cannot Withdraw more than you are allowed");     //检查用户提取的数量不能超过批准额度，否则退回并弹出“”

    hasWithdrawn[msg.sender] = true;     //把这个人标记为已经取过了
    treasureAmount -= allowance;     //从宝藏总数中扣掉他的额度
    withdrawalAllowance[msg.sender] = 0;     //把这个人的批准额度清零

}

//只有管理员能重置某个人的“已取”状态
function resetWithdrawalStatus(address user) public onlyOwner {     //定义一个函数，让管理员能把指定的人的“已取过”状态重置
    hasWithdrawn[user] = false;     //把这个人重新设置为“没取过”
}

//只有管理员才能把管理员省身份交给别人
function transferOwnership(address newOwner) public onlyOwner{     //定义一个函数，管理员输入一个新地址，让那个人成为一个新的管理员
    require(newOwner != address(0), "Invalid address");    //检查新地址不能是空地址，否则退回并弹出“” 
    owner = newOwner;     //把新地址设为管理员
}

function getTreasureDetails() public view onlyOwner returns (uint256) {     管理员可以查看宝藏总数，只能读取一个数字
    return treasureAmount;     
}

}