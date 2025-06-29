// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@title 管理员权限控制的宝藏分发合约 AdminOnly
///@author yuheng
///@notice 本合约允许管理员添加宝藏、授权领取、管理权限
///@dev 使用 onlyOwner 修饰符确保敏感操作仅限管理员执行

contract AdminOnly {

    //状态变量定义
    address public owner;    // 声明当前合约管理员（初始为部署者）
    uint256 public treasureAmount;  // 声明合约中当前的宝藏总额
    mapping(address => uint256) public withdrawalAllowance; // 每个地址被授权可领取的金额
    mapping(address => bool) public hasWithdrawn;    // 是否已经领取过宝藏（防止重复领取）

    //@notice 构造函数：设置部署者为初始管理员
    constructor() {
        owner = msg.sender;
    }
    //@notice 管理员授权领取宝藏 Only the owner can approve withdrawals，仅允许管理员调用的函数修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _;  // 执行修饰函数本体
    }
    //@notice 管理员添加宝藏金额
    //@param amount 要添加的金额
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }
    //@notice 管理员为某地址分配领取额度 Only the owner can approve withdrawals 授权用户领取宝藏
    //@param recipient 被授权地址
    //@param amount 授权金额
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
    }
    //@notice 用户提取宝藏（管理员可直接提取） Anyone can attempt to withdraw, but only those with allowance will succeed 用户领取宝藏（或管理员自取）
    //@param amount 想要提取的金额
    function withdrawTreasure(uint256 amount) public {
        // 管理员可直接提取（无授权检查）
        if (msg.sender == owner) {  
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount -= amount;
            return;
        }
        // 非管理员提取流程 Check if user has an allowance and hasn't withdrawn yet
        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance > 0, "You don't have any treasure allowance");    // 无额度
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");  // 防止重复提取
        require(allowance <= treasureAmount, "Not enough treasure in the chest");   // 总余额不足
        require(allowance >= amount, "Cannot withdraw more than you are allowed"); // 不得超过授权额度 condition to check if user is withdrawing more than allowed
        // 扣除余额、清除授权并标记为已提取
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] = 0;
        
    }
    //notice 重置领取状态，使该用户可重新提取宝藏,Only the owner can transfer ownership 管理员重置某用户领取状态
    //@param user 要重置的用户地址
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }
    //@notice 转移管理员权限给新地址
    // @param newOwner 新管理员地址
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address (0), "Invalid address"); // 避免转给零地址
        owner = newOwner;
    }
    //@notice 管理员查看宝藏总额
    // @return 当前宝藏总金额
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }

}
