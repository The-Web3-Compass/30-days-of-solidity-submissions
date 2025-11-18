// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;
    uint256 public constant COOLDOWN_TIME = 300; // 5 minutes in seconds
    uint256 public constant MAX_WITHDRAWAL_PER_USER = 100 ether;

    struct UserWithdrawalData {
        uint256 allowance;
        bool hasWithdrawn;
        uint256 lastWithdrawTime;
    }

    mapping(address => UserWithdrawalData) public userWithdrawalData;

    // Events
    event TreasureAdded(uint256 amount);
    event WithdrawalApproved(address indexed recipient, uint256 amount);
    event TreasureWithdrawn(address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WithdrawalStatusReset(address indexed user);
    event CooldownActive(address indexed user, uint256 remainingTime);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _;
    }

    // --- Owner Functions ---
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
        emit TreasureAdded(amount);
    }

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        require(amount <= MAX_WITHDRAWAL_PER_USER, "Amount exceeds user withdrawal limit");

        userWithdrawalData[recipient].allowance = amount;
        userWithdrawalData[recipient].hasWithdrawn = false;
        emit WithdrawalApproved(recipient, amount);
    }

    function resetWithdrawalStatus(address user) public onlyOwner {
        userWithdrawalData[user].hasWithdrawn = false;
        emit WithdrawalStatusReset(user);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // --- User Functions ---
    function withdrawTreasure() public {
        UserWithdrawalData storage userData = userWithdrawalData[msg.sender];
        uint256 currentTime = block.timestamp;
        uint256 amount = userData.allowance;

        // Cooldown check
        if (userData.lastWithdrawTime > 0) {
            require(
                currentTime >= userData.lastWithdrawTime + COOLDOWN_TIME,
                "Cooldown period active"
            );
        }

        // Owner bypasses limits
        if (msg.sender == owner) {
            treasureAmount -= amount;
            payable(msg.sender).transfer(amount);
            emit TreasureWithdrawn(msg.sender, amount);
            return;
        }

        // Normal user checks
        require(amount > 0, "No allowance");
        require(!userData.hasWithdrawn, "Already withdrawn");
        require(amount <= treasureAmount, "Insufficient treasure");

        // Update state
        userData.hasWithdrawn = true;
        userData.lastWithdrawTime = currentTime;
        treasureAmount -= amount;
        userData.allowance = 0;

        payable(msg.sender).transfer(amount);
        emit TreasureWithdrawn(msg.sender, amount);
    }

    // --- View Functions ---
    function getUserWithdrawalStatus(address user) public view returns (
        uint256 allowance,
        bool hasWithdrawn,
        uint256 lastWithdrawTime,
        uint256 cooldownRemaining,
        bool canWithdrawNow
    ) {
        UserWithdrawalData memory data = userWithdrawalData[user];
        uint256 currentTime = block.timestamp;

        if (data.lastWithdrawTime > 0 && data.lastWithdrawTime + COOLDOWN_TIME > currentTime) {
            cooldownRemaining = (data.lastWithdrawTime + COOLDOWN_TIME) - currentTime;
            canWithdrawNow = false;
        } else {
            cooldownRemaining = 0;
            canWithdrawNow = (data.allowance > 0 && !data.hasWithdrawn);
        }

        return (
            data.allowance,
            data.hasWithdrawn,
            data.lastWithdrawTime,
            cooldownRemaining,
            canWithdrawNow
        );
    }

    function getMaxWithdrawalLimit() public pure returns (uint256) {
        return MAX_WITHDRAWAL_PER_USER;
    }

    function getCooldownTime() public pure returns (uint256) {
        return COOLDOWN_TIME;
    }

    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }

    // Fallback to reject direct ETH sends
    receive() external payable {
        revert("Use addTreasure() to add funds");
    }
}