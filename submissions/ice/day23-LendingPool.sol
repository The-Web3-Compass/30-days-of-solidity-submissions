// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SimpleLendingPool
 * @dev 简化版资产借贷系统
 * 
 * 核心功能：
 * 1. 存款（Deposit）
 *    - 用户可以存入ERC20代币
 *    - 存款可以赚取利息（10%年化）
 *    - 随时可以提取本金和利息
 * 
 * 2. 借款（Borrow）
 *    - 用户可以借入代币
 *    - 需要支付利息（10%年化）
 *    - 借款金额不能超过存款金额
 * 
 * 3. 利息计算
 *    - 使用简单的时间加权计算
 *    - 年化利率固定为10%
 */
contract SimpleLendingPool is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // 常量
    uint256 public constant INTEREST_RATE = 10; // 年化利率 10%
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    // 用户存款结构体
    struct Deposit {
        uint256 amount;           // 存款金额
        uint256 timestamp;        // 存款时间
    }

    // 用户借款结构体
    struct Borrow {
        uint256 amount;           // 借款金额
        uint256 timestamp;        // 借款时间
    }

    // 状态变量
    mapping(address => mapping(address => Deposit)) public deposits; // 用户存款
    mapping(address => mapping(address => Borrow)) public borrows;  // 用户借款
    mapping(address => bool) public supportedTokens;                // 支持的代币

    // 事件
    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event Deposited(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);
    event Borrowed(address indexed user, address indexed token, uint256 amount);
    event Repaid(address indexed user, address indexed token, uint256 amount);

    constructor() Ownable(msg.sender) {
    }

    /**
     * @dev 添加支持的代币
     */
    function addToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        supportedTokens[token] = true;
        emit TokenAdded(token);
    }

    /**
     * @dev 移除支持的代币
     */
    function removeToken(address token) external onlyOwner {
        supportedTokens[token] = false;
        emit TokenRemoved(token);
    }

    /**
     * @dev 计算利息
     */
    function calculateInterest(uint256 principal, uint256 timestamp) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - timestamp;
        return (principal * INTEREST_RATE * timeElapsed) / (SECONDS_PER_YEAR * 100);
    }

    /**
     * @dev 获取存款余额（包含利息）
     */
    function getDepositBalance(address user, address token) public view returns (uint256) {
        Deposit memory userDeposit = deposits[user][token];
        if (userDeposit.amount == 0) return 0;
        
        uint256 interest = calculateInterest(userDeposit.amount, userDeposit.timestamp);
        return userDeposit.amount + interest;
    }

    /**
     * @dev 获取借款余额（包含利息）
     */
    function getBorrowBalance(address user, address token) public view returns (uint256) {
        Borrow memory userBorrow = borrows[user][token];
        if (userBorrow.amount == 0) return 0;
        
        uint256 interest = calculateInterest(userBorrow.amount, userBorrow.timestamp);
        return userBorrow.amount + interest;
    }

    /**
     * @dev 存款
     */
    function deposit(address token, uint256 amount) external nonReentrant {
        require(supportedTokens[token], "Token not supported");
        require(amount > 0, "Amount must be greater than 0");

        // 转入代币
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // 更新存款记录
        Deposit storage userDeposit = deposits[msg.sender][token];
        if (userDeposit.amount > 0) {
            // 如果已有存款，先计算利息
            uint256 interest = calculateInterest(userDeposit.amount, userDeposit.timestamp);
            userDeposit.amount += interest;
        }
        userDeposit.amount += amount;
        userDeposit.timestamp = block.timestamp;

        emit Deposited(msg.sender, token, amount);
    }

    /**
     * @dev 提款
     */
    function withdraw(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        uint256 balance = getDepositBalance(msg.sender, token);
        require(balance >= amount, "Insufficient balance");

        // 更新存款记录
        Deposit storage userDeposit = deposits[msg.sender][token];
        userDeposit.amount = balance - amount;
        userDeposit.timestamp = block.timestamp;

        // 转出代币
        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, token, amount);
    }

    /**
     * @dev 借款
     */
    function borrow(address token, uint256 amount) external nonReentrant {
        require(supportedTokens[token], "Token not supported");
        require(amount > 0, "Amount must be greater than 0");

        // 检查用户是否有足够的存款作为担保
        uint256 depositBalance = getDepositBalance(msg.sender, token);
        require(depositBalance >= amount, "Insufficient deposit");

        // 更新借款记录
        Borrow storage userBorrow = borrows[msg.sender][token];
        if (userBorrow.amount > 0) {
            // 如果已有借款，先计算利息
            uint256 interest = calculateInterest(userBorrow.amount, userBorrow.timestamp);
            userBorrow.amount += interest;
        }
        userBorrow.amount += amount;
        userBorrow.timestamp = block.timestamp;

        // 转出代币
        IERC20(token).safeTransfer(msg.sender, amount);

        emit Borrowed(msg.sender, token, amount);
    }

    /**
     * @dev 还款
     */
    function repay(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        uint256 borrowBalance = getBorrowBalance(msg.sender, token);
        require(borrowBalance > 0, "No debt to repay");

        // 计算实际还款金额
        uint256 repayAmount = amount > borrowBalance ? borrowBalance : amount;

        // 转入代币
        IERC20(token).safeTransferFrom(msg.sender, address(this), repayAmount);

        // 更新借款记录
        Borrow storage userBorrow = borrows[msg.sender][token];
        userBorrow.amount = borrowBalance - repayAmount;
        userBorrow.timestamp = block.timestamp;

        emit Repaid(msg.sender, token, repayAmount);
    }
}