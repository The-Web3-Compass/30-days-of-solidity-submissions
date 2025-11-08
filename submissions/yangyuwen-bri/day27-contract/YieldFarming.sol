// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 引入OpenZeppelin的ERC20接口，方便与任意ERC20代币交互
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// 引入重入攻击防护
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// 引入安全类型转换库，防止溢出
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

// 扩展ERC20接口，获取代币的decimals、name、symbol等元数据
interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

/// @title Yield Farming Platform
/// @notice 用户可以质押ERC20代币，按时间获得奖励，支持紧急取回和管理员补充奖励池
contract YieldFarming is ReentrancyGuard {
    using SafeCast for uint256;

    // 用户质押的代币（比如USDT、ETH等）
    IERC20 public stakingToken;
    // 用户获得奖励的代币（可以和stakingToken相同或不同）
    IERC20 public rewardToken;
    // 每秒发放的奖励数量（单位：rewardToken的最小单位）
    uint256 public rewardRatePerSecond;
    // 合约管理员（部署者），只有他能补充奖励池
    address public owner;
    // 记录stakingToken的小数位数，方便后续计算
    uint8 public stakingTokenDecimals;

    // 记录每个用户的质押信息
    struct StakerInfo {
        uint256 stakedAmount;   // 用户已质押的数量
        uint256 rewardDebt;     // 用户已累计但未领取的奖励
        uint256 lastUpdate;     // 上次更新奖励的时间戳
    }
    // 用户地址 => 质押信息
    mapping(address => StakerInfo) public stakers;

    // 事件：用户质押
    event Staked(address indexed user, uint256 amount);
    // 事件：用户取回质押
    event Unstaked(address indexed user, uint256 amount);
    // 事件：用户领取奖励
    event RewardClaimed(address indexed user, uint256 amount);
    // 事件：用户紧急取回
    event EmergencyWithdraw(address indexed user, uint256 amount);
    // 事件：管理员补充奖励池
    event RewardRefilled(address indexed owner, uint256 amount);

    // 只允许管理员调用的修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    /// @notice 构造函数，初始化合约参数
    /// @param _stakingToken 用户质押的代币地址
    /// @param _rewardToken  用户获得奖励的代币地址
    /// @param _rewardRatePerSecond 每秒发放的奖励数量
    constructor(address _stakingToken, address _rewardToken, uint256 _rewardRatePerSecond) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRatePerSecond = _rewardRatePerSecond;
        owner = msg.sender;

        // 尝试获取stakingToken的小数位数，失败则默认为18
        try IERC20Metadata(_stakingToken).decimals() returns (uint8 decimals) {
            stakingTokenDecimals = decimals;
        } catch (bytes memory) {
            stakingTokenDecimals = 18;
        }
    }

    /// @notice 用户质押代币，开始计息
    /// @param amount 质押数量
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0");
        updateRewards(msg.sender); // 先结算之前的奖励
        stakingToken.transferFrom(msg.sender, address(this), amount); // 从用户转入合约
        stakers[msg.sender].stakedAmount += amount; // 累加质押数量
        emit Staked(msg.sender, amount);
    }

    /// @notice 用户取回部分或全部质押，同时结算奖励
    /// @param amount 取回数量
    function unstake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot unstake 0");
        require(stakers[msg.sender].stakedAmount >= amount, "Not enough staked");
        updateRewards(msg.sender); // 先结算奖励
        stakers[msg.sender].stakedAmount -= amount; // 扣除质押数量
        stakingToken.transfer(msg.sender, amount); // 转回用户
        emit Unstaked(msg.sender, amount);
    }

    /// @notice 用户领取已累计的奖励
    function claimRewards() external nonReentrant {
        updateRewards(msg.sender); // 先结算到当前
        uint256 reward = stakers[msg.sender].rewardDebt;
        require(reward > 0, "No rewards to claim");
        require(rewardToken.balanceOf(address(this)) >= reward, "Insufficient reward token balance");
        stakers[msg.sender].rewardDebt = 0; // 清空奖励
        rewardToken.transfer(msg.sender, reward); // 发放奖励
        emit RewardClaimed(msg.sender, reward);
    }

    /// @notice 紧急取回全部质押，放弃所有奖励
    function emergencyWithdraw() external nonReentrant {
        uint256 amount = stakers[msg.sender].stakedAmount;
        require(amount > 0, "Nothing staked");
        stakers[msg.sender].stakedAmount = 0;
        stakers[msg.sender].rewardDebt = 0;
        stakers[msg.sender].lastUpdate = block.timestamp;
        stakingToken.transfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }

    /// @notice 管理员补充奖励池
    /// @param amount 补充的奖励数量
    function refillRewards(uint256 amount) external onlyOwner {
        rewardToken.transferFrom(msg.sender, address(this), amount);
        emit RewardRefilled(msg.sender, amount);
    }

    /// @notice 内部函数，更新用户的奖励
    /// @param user 用户地址
    function updateRewards(address user) internal {
        StakerInfo storage staker = stakers[user];
        if (staker.stakedAmount > 0) {
            uint256 timeDiff = block.timestamp - staker.lastUpdate; // 距离上次操作的秒数
            uint256 rewardMultiplier = 10 ** stakingTokenDecimals; // 统一小数位
            uint256 pendingReward = (timeDiff * rewardRatePerSecond * staker.stakedAmount) / rewardMultiplier;
            staker.rewardDebt += pendingReward; // 累加奖励
        }
        staker.lastUpdate = block.timestamp; // 更新时间
    }

    /// @notice 查询用户当前可领取的奖励（不改变状态）
    /// @param user 用户地址
    /// @return 可领取的奖励数量
    function pendingRewards(address user) external view returns (uint256) {
        StakerInfo memory staker = stakers[user];
        uint256 pendingReward = staker.rewardDebt;
        if (staker.stakedAmount > 0) {
            uint256 timeDiff = block.timestamp - staker.lastUpdate;
            uint256 rewardMultiplier = 10 ** stakingTokenDecimals;
            pendingReward += (timeDiff * rewardRatePerSecond * staker.stakedAmount) / rewardMultiplier;
        }
        return pendingReward;
    }

    /// @notice 查询stakingToken的小数位数，方便前端显示
    function getStakingTokenDecimals() external view returns (uint8) {
        return stakingTokenDecimals;
    }
}
