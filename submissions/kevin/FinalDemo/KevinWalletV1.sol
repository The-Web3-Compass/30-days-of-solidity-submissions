// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Kevin Smart Contract Wallet V1
/// @notice 基于 30 天 Solidity 课程的智能合约钱包
/// @dev 集成了社交恢复、批量执行、DeFi 集成等功能
contract KevinWalletV1 is ReentrancyGuard {
    
    // ============ 状态变量 ============
    
    address public owner;
    bool public paused;
    
    // 社交恢复 (Day03 mapping + Day28 DAO投票)
    address[] public guardians;
    mapping(address => bool) public isGuardian;
    
    struct RecoveryRequest {
        address newOwner;
        uint256 approvalCount;
        mapping(address => bool) hasApproved;
        uint256 timestamp;
        bool isActive;
    }
    RecoveryRequest public recoveryRequest;
    
    // ============ 事件 ============
    
    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event GuardianAdded(address indexed guardian);
    event GuardianRemoved(address indexed guardian);
    event RecoveryInitiated(address indexed initiator, address indexed newOwner, uint256 timestamp);
    event RecoveryApproved(address indexed guardian, address indexed newOwner);
    event RecoveryExecuted(address indexed oldOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    
    // ============ 修饰符 ============
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier onlyGuardian() {
        require(isGuardian[msg.sender], "Not guardian");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }
    
    // ============ 构造函数 ============
    
    constructor() {
        owner = msg.sender;
        paused = false;
    }
    
    // ============ 基础钱包功能 (Day01-11) ============
    
    /// @notice 存入 ETH 到钱包
    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Deposit must be more than 0");
        emit Deposited(msg.sender, msg.value);
    }
    
    /// @notice 提取 ETH (仅 Owner)
    /// @param amount 提取金额
    function withdraw(uint256 amount) external onlyOwner whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be more than 0");
        require(address(this).balance >= amount, "Insufficient balance");
        
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "ETH transfer failed");
        
        emit Withdrawn(owner, amount);
    }
    
    /// @notice 查询钱包余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // ============ 守护者管理 (Day03 mapping) ============
    
    /// @notice 添加守护者
    /// @param guardian 守护者地址
    function addGuardian(address guardian) external onlyOwner {
        require(guardian != address(0), "Invalid guardian address");
        require(!isGuardian[guardian], "Already a guardian");
        require(guardian != owner, "Owner cannot be guardian");
        
        guardians.push(guardian);
        isGuardian[guardian] = true;
        
        emit GuardianAdded(guardian);
    }
    
    /// @notice 移除守护者
    /// @param guardian 守护者地址
    function removeGuardian(address guardian) external onlyOwner {
        require(isGuardian[guardian], "Not a guardian");
        
        isGuardian[guardian] = false;
        
        // 从数组中移除
        for (uint256 i = 0; i < guardians.length; i++) {
            if (guardians[i] == guardian) {
                guardians[i] = guardians[guardians.length - 1];
                guardians.pop();
                break;
            }
        }
        
        emit GuardianRemoved(guardian);
    }
    
    /// @notice 获取所有守护者
    function getGuardians() external view returns (address[] memory) {
        return guardians;
    }
    
    // ============ 社交恢复 (Day28 DAO投票) ============
    
    /// @notice 发起恢复请求
    /// @param newOwner 新的 Owner 地址
    function initiateRecovery(address newOwner) external onlyGuardian {
        require(newOwner != address(0), "Invalid new owner");
        require(!recoveryRequest.isActive, "Recovery already in progress");
        require(guardians.length >= 3, "Need at least 3 guardians");
        
        recoveryRequest.newOwner = newOwner;
        recoveryRequest.approvalCount = 0;
        recoveryRequest.timestamp = block.timestamp;
        recoveryRequest.isActive = true;
        
        emit RecoveryInitiated(msg.sender, newOwner, block.timestamp);
    }
    
    /// @notice 守护者批准恢复
    function approveRecovery() external onlyGuardian {
        require(recoveryRequest.isActive, "No active recovery");
        require(!recoveryRequest.hasApproved[msg.sender], "Already approved");
        
        recoveryRequest.hasApproved[msg.sender] = true;
        recoveryRequest.approvalCount++;
        
        emit RecoveryApproved(msg.sender, recoveryRequest.newOwner);
    }
    
    /// @notice 执行恢复 (需要 2/3 守护者批准)
    function executeRecovery() external {
        require(recoveryRequest.isActive, "No active recovery");
        
        uint256 requiredApprovals = (guardians.length * 2) / 3;
        require(recoveryRequest.approvalCount >= requiredApprovals, "Not enough approvals");
        
        address oldOwner = owner;
        owner = recoveryRequest.newOwner;
        
        // 重置恢复请求
        recoveryRequest.isActive = false;
        
        emit RecoveryExecuted(oldOwner, owner);
        emit OwnershipTransferred(oldOwner, owner);
    }
    
    /// @notice 取消恢复 (仅 Owner)
    function cancelRecovery() external onlyOwner {
        require(recoveryRequest.isActive, "No active recovery");
        recoveryRequest.isActive = false;
    }
    
    /// @notice 获取恢复信息
    function getRecoveryInfo() external view returns (
        address newOwner,
        uint256 approvalCount,
        uint256 timestamp,
        bool isActive
    ) {
        return (
            recoveryRequest.newOwner,
            recoveryRequest.approvalCount,
            recoveryRequest.timestamp,
            recoveryRequest.isActive
        );
    }
    
    // ============ 批量执行 (Day09 external call) ============
    
    /// @notice 批量执行多个调用
    /// @param dests 目标合约地址数组
    /// @param values ETH 金额数组
    /// @param funcs 函数调用数据数组
    function executeBatch(
        address[] calldata dests,
        uint256[] calldata values,
        bytes[] calldata funcs
    ) external onlyOwner whenNotPaused nonReentrant {
        require(
            dests.length == values.length && values.length == funcs.length,
            "Array lengths must match"
        );
        
        for (uint256 i = 0; i < dests.length; i++) {
            (bool success, ) = dests[i].call{value: values[i]}(funcs[i]);
            require(success, "Batch call failed");
        }
    }
    
    // ============ DeFi 集成 - 借贷 (Day23) ============
    
    /// @notice 存入到借贷协议
    function depositToLending(address lendingPool, uint256 amount) external onlyOwner whenNotPaused {
        (bool success, ) = lendingPool.call{value: amount}(
            abi.encodeWithSignature("deposit()")
        );
        require(success, "Lending deposit failed");
    }
    
    /// @notice 从借贷协议提取
    function withdrawFromLending(address lendingPool, uint256 amount) external onlyOwner whenNotPaused {
        (bool success, ) = lendingPool.call(
            abi.encodeWithSignature("withdraw(uint256)", amount)
        );
        require(success, "Lending withdraw failed");
    }
    
    /// @notice 从借贷协议借款
    function borrowFromLending(address lendingPool, uint256 amount) external onlyOwner whenNotPaused {
        (bool success, ) = lendingPool.call(
            abi.encodeWithSignature("borrow(uint256)", amount)
        );
        require(success, "Borrow failed");
    }
    
    /// @notice 还款到借贷协议
    function repayToLending(address lendingPool, uint256 amount) external onlyOwner whenNotPaused {
        (bool success, ) = lendingPool.call{value: amount}(
            abi.encodeWithSignature("repay(uint256)", amount)
        );
        require(success, "Repay failed");
    }
    
    // ============ DeFi 集成 - 质押 (Day27) ============
    
    /// @notice 质押代币到挖矿池
    function stakeToFarming(
        address farmingPool,
        address token,
        uint256 amount
    ) external onlyOwner whenNotPaused {
        IERC20(token).approve(farmingPool, amount);
        
        (bool success, ) = farmingPool.call(
            abi.encodeWithSignature("stake(uint256)", amount)
        );
        require(success, "Stake failed");
    }
    
    /// @notice 从挖矿池取消质押
    function unstakeFromFarming(address farmingPool, uint256 amount) external onlyOwner whenNotPaused {
        (bool success, ) = farmingPool.call(
            abi.encodeWithSignature("unstake(uint256)", amount)
        );
        require(success, "Unstake failed");
    }
    
    /// @notice 领取挖矿奖励
    function claimFarmingRewards(address farmingPool) external onlyOwner whenNotPaused {
        (bool success, ) = farmingPool.call(
            abi.encodeWithSignature("claimRewards()")
        );
        require(success, "Claim rewards failed");
    }
    
    // ============ DeFi 集成 - DEX (Day30) ============
    
    /// @notice 在 DEX 上交换代币
    function swapOnDex(
        address dexPair,
        address inputToken,
        uint256 inputAmount
    ) external onlyOwner whenNotPaused {
        IERC20(inputToken).approve(dexPair, inputAmount);
        
        (bool success, ) = dexPair.call(
            abi.encodeWithSignature("swap(address,uint256)", inputToken, inputAmount)
        );
        require(success, "Swap failed");
    }
    
    /// @notice 添加流动性到 DEX
    function addLiquidityToDex(
        address dexPair,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) external onlyOwner whenNotPaused {
        IERC20(tokenA).approve(dexPair, amountA);
        IERC20(tokenB).approve(dexPair, amountB);
        
        (bool success, ) = dexPair.call(
            abi.encodeWithSignature("addLiquidity(uint256,uint256)", amountA, amountB)
        );
        require(success, "Add liquidity failed");
    }
    
    /// @notice 从 DEX 移除流动性
    function removeLiquidityFromDex(address dexPair, uint256 lpAmount) external onlyOwner whenNotPaused {
        (bool success, ) = dexPair.call(
            abi.encodeWithSignature("removeLiquidity(uint256)", lpAmount)
        );
        require(success, "Remove liquidity failed");
    }
    
    // ============ 代币操作 ============
    
    /// @notice 授权代币给其他合约
    function approveToken(
        address token,
        address spender,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).approve(spender, amount);
    }
    
    /// @notice 查询代币余额
    function getTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
    
    // ============ 暂停功能 (Day20 安全) ============
    
    /// @notice 暂停合约
    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }
    
    /// @notice 恢复合约
    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }
    
    // ============ 接收 ETH ============
    
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }
    
    fallback() external payable {
        emit Deposited(msg.sender, msg.value);
    }
}
