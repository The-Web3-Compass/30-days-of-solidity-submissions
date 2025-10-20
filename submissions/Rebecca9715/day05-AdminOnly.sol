// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    // State variables
    address public owner;
    // 全部金额
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance; //对于常规用户增加允许，需要owner权限
    mapping(address => bool) public hasWithdrawn;
    
    // Constructor sets the contract creator as the owner
    constructor() {
        owner = msg.sender;
    }
    
    // Modifier for owner-only functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _;
    }
    
    // 只有owner可以存钱
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }
    
    // Only the owner can approve withdrawals
    // 后续也可以增加功能，owner可以允许其他用户进行存钱
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
    }
    
    
    // Anyone can attempt to withdraw, but only those with allowance will succeed
    function withdrawTreasure(uint256 amount) public {

        // owner直接可以取钱
        if(msg.sender == owner){
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount-= amount;

            return;
        }
        uint256 allowance = withdrawalAllowance[msg.sender];
        
        // Check if user has an allowance and hasn't withdrawn yet
        require(allowance > 0, "You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");
        require(allowance >= amount, "Cannot withdraw more than you are allowed"); // condition to check if user is withdrawing more than allowed
        
        // Mark as withdrawn and reduce treasure
        hasWithdrawn[msg.sender] = true; //控制取钱次数
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] = 0;
        
    }
    
    // 已经取过一次钱会在map中记录
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }
    
    // Only the owner can transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }
}

// Day05
// 1. 部署，并且自动会录入当前启动部署的address为owner
// 2. 输入金额，点击addTreasure，可以存钱，只有owner可以存钱
// 3. 输入金额，点击withdrawTreasure，owner可以直接取钱，其他人需要进入判断模式
// 4. 选择上面的某一个账户，点击approveWithdrawal和金额，表示允许该用户取钱的金额
// 5. 切换到这个账户上，withdrawTreasure可以取钱，只能在允许的额度内取钱，取完一次会自动标记已取钱
// 6. 只有owner账户可以将这个账户的标记reset成false，这个账户才能继续取钱
// 7. 只有owner可以transfer owner账户，将owner账户转移给其他账户
