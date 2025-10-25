// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    //声明变量
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawAllowance;
    mapping(address => bool) public hasWithdrawn;
    //记录用户是否完成某项操作

    constructor() {
        owner = msg.sender;
    }

//Modifier for owner-only functions 通过修饰符实现可复用的访问控制
modifier onlyOwner(){
    require(msg.sender == owner, "Access denied: Only the owner can perform this action");
    _;//占位符，_ 表示权限检查之后的函数主体将被插入的位置
    //只有检查通过时，函数主体的代码才会被执行。
}

//只有Owner才能add宝藏
function addTreasure(uint256 Amount) public onlyOwner {
    treasureAmount += Amount;
}

//只有Owner才能授权ta人取宝
function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
    require(amount <= treasureAmount, "Not enough treasure available");
    withdrawAllowance[recipient] = amount;
}

//实际取宝过程
function withdrawTreasure(uint256 amount) public {
    //①拥有者自己取宝，只要满足宝箱宝藏足够就可以
    if(msg.sender == owner){
        require(amount <= treasureAmount, "Not enough treasure available or this action.");
        treasureAmount-= amount;

        return;
    }

    uint256 allowance = withdrawAllowance[msg.sender];
    require(allowance > 0, "You don't have any treasure allowance");
    //检查是被批准提取
    require(!hasWithdrawn[msg.sender], "You have already withdrawn our treasure");
    //检查是否已经够提取过
    require(allowance <= treasureAmount, "Not enough treasure in the chest");
    //宝箱里是否仍有足够的宝物？
    require(allowance >= amount, "Cannot withdraw more than you are allowed");
    //检查用户提取的数量是否超过允许提取的数量

    //完成取宝操作
    hasWithdrawn[msg.sender] = true;
    treasureAmount -= allowance;
    withdrawAllowance[msg.sender] = 0;
    //将用户标记为“已提取”；
    //从宝箱中减去被批准的提取数量；
    //将该用户的提取额度重置为零，防止重复提取。

}

//重置用户的提取状态
function resetWithdrawalStatus(address user) public onlyOwner {
    hasWithdrawn[user] =false;
}
//让某个用户再次拥有资格提取宝物

//只有Owner才能转移合约拥有权
function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Invalid address");
    owner = newOwner;
}

//查看宝箱信息（仅限拥有者）
function getTreasureDetails() public view onlyOwner returns (uint256) {
    return treasureAmount;
}

}