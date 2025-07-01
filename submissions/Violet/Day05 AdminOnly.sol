// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreasureChest {
    address public owner;  // 合约所有者
    uint256 public treasure;  // 宝箱中的宝藏数量
    
    // 用户可提取的宝藏数量和提取状态
    mapping(address => uint256) public allowances;
    mapping(address => bool) public hasWithdrawn;
    
    // 仅所有者修改器
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    // 构造函数 - 设置合约部署者为所有者
    constructor() {
        owner = msg.sender;
    }
    
    // 添加宝藏到宝箱（仅所有者）
    function addTreasure() external payable onlyOwner {
        treasure += msg.value;
    }
    
    // 设置用户提取额度（仅所有者）
    function setAllowance(address user, uint256 amount) external onlyOwner {
        allowances[user] = amount;
    }
    
    // 用户提取宝藏
    function withdraw() external {
        require(!hasWithdrawn[msg.sender], "Already withdrawn");
        require(allowances[msg.sender] > 0, "No allowance");
        require(treasure >= allowances[msg.sender], "Not enough treasure");
        
        uint256 amount = allowances[msg.sender];
        treasure -= amount;
        hasWithdrawn[msg.sender] = true;
        
        payable(msg.sender).transfer(amount);
    }
    
    // 所有者提取宝藏（任意数量）
    function ownerWithdraw(uint256 amount) external onlyOwner {
        require(amount <= treasure, "Amount too high");
        treasure -= amount;
        payable(owner).transfer(amount);
    }
    
    // 重置用户提取状态（仅所有者）
    function resetUser(address user) external onlyOwner {
        hasWithdrawn[user] = false;
    }
    
    // 转移所有权（仅所有者）
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}