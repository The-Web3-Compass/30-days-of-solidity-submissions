// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGoldToken {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract FortKnox {
    IGoldToken public goldToken;
    mapping(address => uint256) public deposits;
    
    bool private locked;
    
    event GoldDeposited(address indexed user, uint256 amount);
    event GoldWithdrawn(address indexed user, uint256 amount);
    
    modifier nonReentrant() {
        require(!locked, "Reentrancy detected");
        locked = true;
        _;
        locked = false;
    }
    
    constructor(address _goldTokenAddress) {
        goldToken = IGoldToken(_goldTokenAddress);
    }
    
    function depositGold(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be positive");
        // 修复：添加了缺失的amount参数
        require(goldToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        deposits[msg.sender] += amount;
        emit GoldDeposited(msg.sender, amount);
    }
    
    function withdrawGold(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        
        deposits[msg.sender] -= amount;
        require(goldToken.transfer(msg.sender, amount), "Transfer failed");
        emit GoldWithdrawn(msg.sender, amount);
    }
    
    function withdrawAllGold() external nonReentrant {
        uint256 amount = deposits[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        deposits[msg.sender] = 0;
        require(goldToken.transfer(msg.sender, amount), "Transfer failed");
        emit GoldWithdrawn(msg.sender, amount);
    }
    
    function getGoldBalance() external view returns (uint256) {
        return deposits[msg.sender];
    }
    
    function getVaultBalance() external view returns (uint256) {
        return goldToken.balanceOf(address(this));
    }
}
