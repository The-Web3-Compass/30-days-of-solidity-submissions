// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    // 状态变量
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;
    
    // 全局调用一次，定义合约拥有者
    constructor() {
        // “谁部署了这个合约，谁就是合约的拥有者。”
        owner = msg.sender;
    }
    
    // 检查调用者是否是owner，访问控制的实现方法
    // 定义一个修饰符，后续利用这个实现访问控制
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _;
    }
    
    // 只有owner才能修改宝物数量
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }
    
    // owner有授权的权利，授权他人可以取宝
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
    }
    
    
    // 每个人都可以尝试，但是只有被授权的人才能成功
    function withdrawTreasure(uint256 amount) public {

        if(msg.sender == owner){
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount-= amount;

            return;
        }
        
        // 取出当前调用者对应的withdrawalAllowance值
        uint256 allowance = withdrawalAllowance[msg.sender];
        
       // 多种条件对于不同的情况
        require(allowance > 0, "You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");
        require(allowance >= amount, "Cannot withdraw more than you are allowed"); // condition to check if user is withdrawing more than allowed
        
        // 条件都通过，实现真正的逻辑，授权，取出物品，数量-1
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] = 0;
        
    }
    
    // 只有owner可以重置
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }
    
    // 只有owner才能转移新owner
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }
}