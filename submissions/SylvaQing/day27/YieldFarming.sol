// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol"; 
import "./IERC20Metadata.sol";

/// @title 收益耕作平台
///     质押代币以随时间赚取奖励,可选紧急提取和管理员补充
contract YieldFarming is ReentrancyGuard{

using SafeCast for uint256;

IERC20 public stakingToken;//用户存入农场的资产
IERC20 public rewardToken;//用户将作为奖励赚取的代币

uint256 public rewardRatePerSecond; // 每秒分配的奖励

address public owner;

uint8 public stakingTokenDecimals; //根据小数位数正确缩放数字

// 跟踪每个用户 – 结构和映射
struct StakerInfo {
    uint256 stakedAmount; //用户存入农场的质押代币数量
    uint256 rewardDebt;//用户已经赚取但尚未领取的奖励数量。
    uint256 lastUpdate;//上次更新用户奖励的时间
}

mapping(address => StakerInfo) public stakers; //用户的地址映射到他们的个人 StakerInfo 数据

// 事件：质押代币、取消质押(提取)、领取他们的待处理奖励、立即取出他们的质押而不等待奖励、管理员用新的奖励代币补充合约
event Staked(address indexed user, uint256 amount);
event Unstaked(address indexed user, uint256 amount);
event RewardClaimed(address indexed user, uint256 amount);
event EmergencyWithdraw(address indexed user, uint256 amount);
event RewardRefilled(address indexed owner, uint256 amount);


modifier onlyOwner() {
    require(msg.sender == owner, "Not the owner");
    _;
}


constructor(
    address _stakingToken,
    address _rewardToken,
    uint256 _rewardRatePerSecond
) {
    stakingToken = IERC20(_stakingToken);
    rewardToken = IERC20(_rewardToken);
    rewardRatePerSecond = _rewardRatePerSecond;
    owner = msg.sender;

    // 尝试获取小数位数， 这确保我们的奖励计算保持准确，即使跨不同类型的代币。
    try IERC20Metadata(_stakingToken).decimals() returns (uint8 decimals) {
        stakingTokenDecimals = decimals;
    } catch (bytes memory) {
        stakingTokenDecimals = 18; // 如果获取失败,默认为 18 位小数
    }
}
// ==========实义函数=========== //
//更新质押者的奖励
function updateRewards(address user) internal {
    StakerInfo storage staker = stakers[user];

    if (staker.stakedAmount > 0) {
        uint256 timeDiff = block.timestamp - staker.lastUpdate; //计算过了多少时间
        uint256 rewardMultiplier = 10 ** stakingTokenDecimals; // 根据小数位数设置奖励乘数
        uint256 pendingReward = (timeDiff * rewardRatePerSecond * staker.stakedAmount) / rewardMultiplier;//计算待处理奖励
        staker.rewardDebt += pendingReward;//将待处理奖励添加到奖励债务
    }

    staker.lastUpdate = block.timestamp; //更新时间
}

// 用户进入农场并开始赚取
function stake(uint256 amount) external nonReentrant {
    require(amount > 0, "Cannot stake 0");

    //计算并存储用户到目前为止已经赚取的任何待处理奖励。
    updateRewards(msg.sender);

    // 用户的代币正式锁定到农场中
    stakingToken.transferFrom(msg.sender, address(this), amount);
    // 更新余额
    stakers[msg.sender].stakedAmount += amount;

    emit Staked(msg.sender, amount);
}

//取消质押代币并可选择领取奖励
function unstake(uint256 amount) external nonReentrant {
    require(amount > 0, "Cannot unstake 0");
    require(stakers[msg.sender].stakedAmount >= amount, "Not enough staked");

    updateRewards(msg.sender);
    //和上方是逆过程
    stakers[msg.sender].stakedAmount -= amount;
    stakingToken.transfer(msg.sender, amount);

    emit Unstaked(msg.sender, amount);
}

//领取累积的奖励
function claimRewards() external nonReentrant {
    updateRewards(msg.sender);

    uint256 reward = stakers[msg.sender].rewardDebt;
    require(reward > 0, "No rewards to claim");
    require(rewardToken.balanceOf(address(this)) >= reward, "Insufficient reward token balance");

    stakers[msg.sender].rewardDebt = 0; //重置用户的奖励债务
    rewardToken.transfer(msg.sender, reward);//将奖励转给用户

    emit RewardClaimed(msg.sender, reward);
}


//紧急取消质押而不领取奖励
function emergencyWithdraw() external nonReentrant {
    uint256 amount = stakers[msg.sender].stakedAmount;
    require(amount > 0, "Nothing staked");

    // 重置所有用户信息
    stakers[msg.sender].stakedAmount = 0;
    stakers[msg.sender].rewardDebt = 0;
    stakers[msg.sender].lastUpdate = block.timestamp;

    stakingToken.transfer(msg.sender, amount);

    emit EmergencyWithdraw(msg.sender, amount);
}

//管理员可以补充奖励代币
function refillRewards(uint256 amount) external onlyOwner {
    rewardToken.transferFrom(msg.sender, address(this), amount);

    emit RewardRefilled(msg.sender, amount);
}


///     查看待处理奖励而不领取
function pendingRewards(address user) external view returns (uint256) {
    StakerInfo memory staker = stakers[user]; //将用户的质押信息加载到内存中(而不是存储)
    // 由于我们只是读取而不是更改任何东西，使用 memory 节省 gas 并更快。

    uint256 pendingReward = staker.rewardDebt;

    if (staker.stakedAmount > 0) {
        uint256 timeDiff = block.timestamp - staker.lastUpdate;
        uint256 rewardMultiplier = 10 ** stakingTokenDecimals;
        pendingReward += (timeDiff * rewardRatePerSecond * staker.stakedAmount) / rewardMultiplier;
    }

    return pendingReward;
}


/// 查看质押代币小数位数
function getStakingTokenDecimals() external view returns (uint8) {
    return stakingTokenDecimals;
}



}