/**
 * @title YieldFarming
 * @dev 流动性挖矿系统
 * 
 * 什么是流动性挖矿？
 * 流动性挖矿是DeFi中的一种激励机制，用户通过提供交易对的流动性来获得奖励。
 * 比如：用户在DEX中提供ETH/USDT交易对的流动性，获得LP代币，再质押LP代币来挖矿赚取额外代币奖励。
 * 
 * 设计思路：
 * 1. 双代币机制：
 *    - stakingToken: LP代币，用于质押
 *    - rewardToken: 奖励代币，作为挖矿收益
 * 
 * 2. 质押系统（Staking）：
 *    - 用户质押LP代币到合约
 *    - 记录每个用户的质押数量
 *    - 维护总质押量数据
 * 
 * 3. 奖励计算（Reward）：
 *    - 设定每秒奖励率(rewardRate)
 *    - 按质押比例分配奖励
 *    - 公式：用户奖励 = 质押量 × (当前累积奖励 - 上次结算时累积奖励)
 * 
 * 4. 时间管理：
 *    - 7天为一个挖矿周期
 *    - 精确记录最后更新时间
 *    - 支持动态调整奖励率
 * 
 * 5. 用户操作：
 *    - stake(): 质押LP代币
 *    - withdraw(): 提取质押
 *    - getReward(): 领取奖励
 *    - exit(): 一键提取本金和奖励
 * 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract YieldFarming is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // 状态变量
    IERC20 public stakingToken;    // LP代币
    IERC20 public rewardToken;     // 奖励代币
    uint256 public rewardRate;     // 每秒奖励率
    uint256 public lastUpdateTime; // 最后更新时间
    uint256 public rewardPerTokenStored; // 每单位质押代币的累积奖励

    // 用户相关映射
    mapping(address => uint256) public userRewardPerTokenPaid; // 用户已支付的每单位代币奖励
    mapping(address => uint256) public rewards;    // 用户待领取的奖励
    mapping(address => uint256) public balanceOf;  // 用户质押余额

    // 总质押量
    uint256 public totalSupply;

    // 奖励相关参数
    uint256 public constant REWARD_DURATION = 7 days;  // 奖励周期
    uint256 public periodFinish;  // 当前奖励周期结束时间

    // 事件
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);

    constructor(
        address _stakingToken,
        address _rewardToken
    ) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    /**
     * @dev 修改器：更新奖励
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /**
     * @dev 获取最后的有效奖励时间
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /**
     * @dev 计算每个质押代币的奖励
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalSupply);
    }

    /**
     * @dev 计算用户已赚取的奖励
     */
    function earned(address account) public view returns (uint256) {
        return
            ((balanceOf[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    /**
     * @dev 质押代币
     */
    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev 提取质押的代币
     */
    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev 领取奖励
     */
    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /**
     * @dev 退出：提取全部质押并领取奖励
     */
    function exit() external {
        withdraw(balanceOf[msg.sender]);
        getReward();
    }

    /**
     * @dev 添加奖励（仅管理员）
     */
    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / REWARD_DURATION;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / REWARD_DURATION;
        }

        // 确保合约有足够的奖励代币
        uint256 balance = rewardToken.balanceOf(address(this));
        require(rewardRate <= balance / REWARD_DURATION, "Reward rate too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + REWARD_DURATION;
        emit RewardAdded(reward);
    }

    /**
     * @dev 紧急提取质押代币（仅管理员）
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = stakingToken.balanceOf(address(this));
        stakingToken.safeTransfer(owner(), balance);
    }

    /**
     * @dev 紧急提取奖励代币（仅管理员）
     */
    function emergencyRewardWithdraw(uint256 amount) external onlyOwner {
        rewardToken.safeTransfer(owner(), amount);
    }

    // 查看函数
    /**
     * @dev 获取用户质押信息
     */
    function getUserStakeInfo(address user) external view returns (
        uint256 stakedAmount,
        uint256 earnedRewards,
        uint256 rewardRate_,
        uint256 rewardPerToken_,
        uint256 userRewardPaid
    ) {
        return (
            balanceOf[user],
            earned(user),
            rewardRate,
            rewardPerToken(),
            userRewardPerTokenPaid[user]
        );
    }

    /**
     * @dev 获取池子信息
     */
    function getPoolInfo() external view returns (
        uint256 totalStaked,
        uint256 rewardRate_,
        uint256 periodFinish_,
        uint256 lastTimeReward,
        uint256 rewardPerToken_
    ) {
        return (
            totalSupply,
            rewardRate,
            periodFinish,
            lastTimeRewardApplicable(),
            rewardPerToken()
        );
    }
}