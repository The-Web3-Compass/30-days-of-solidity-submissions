
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";//这个导入让我们访问 ERC-20 接口
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";// 重入保护
import "@openzeppelin/contracts/utils/math/SafeCast.sol"; // SafeCast 有助于防止在我们跨不同大小的数字进行数学运算时意外溢出或数据丢失

// 用于获取 ERC-20 元数据(小数位数)的接口
interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);//返回代币使用的小数位数
    function name() external view returns (string memory);//返回人类可读的代币名称(例如，"Dai Stablecoin")
    function symbol() external view returns (string memory);//返回简短的股票代码符号(例如，"DAI")
}

/// @title 收益耕作平台
///     质押代币以随时间赚取奖励,可选紧急提取和管理员补充
contract YieldFarming is ReentrancyGuard {//YieldFarming 合约继承自 OpenZeppelin 的 ReentrancyGuard 合约
    using SafeCast for uint256;
    //允许我们直接在 uint256 数字上调用像 .toUint8()、.toUint128() 等方法 — 并在不冒溢出或奇怪错误风险的情况下安全地在不同类型之间转换。

    IERC20 public stakingToken;//这是用户将质押(锁定)到合约中的代币。
    IERC20 public rewardToken;//这是用户将作为奖励赚取的代币

    uint256 public rewardRatePerSecond; // 每秒分配的奖励

    address public owner;//这存储管理员的钱包地址

    uint8 public stakingTokenDecimals; // 存储质押代币的小数位数

    struct StakerInfo {
        uint256 stakedAmount;//存入农场的质押代币数量
        uint256 rewardDebt;//已经赚取但尚未领取的奖励数量
        uint256 lastUpdate;//这记录我们上次更新用户奖励的时间
    }

    mapping(address => StakerInfo) public stakers;//这将每个用户的地址映射到他们的个人 StakerInfo 数据。

    event Staked(address indexed user, uint256 amount);//当用户质押代币到农场时触发。
    event Unstaked(address indexed user, uint256 amount);//当用户取消质押(提取)他们的代币时触发
    event RewardClaimed(address indexed user, uint256 amount);//当用户领取他们的待处理奖励而不取消质押时触发
    event EmergencyWithdraw(address indexed user, uint256 amount);//当用户立即取出他们的质押而不等待奖励时触发
    event RewardRefilled(address indexed owner, uint256 amount);//当管理员用新的奖励代币补充合约时触发

    modifier onlyOwner() {//修饰符 – 保护仅限管理员的操作
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardRatePerSecond
    ) {
        stakingToken = IERC20(_stakingToken);//设置质押代币
        rewardToken = IERC20(_rewardToken);// 设置奖励代币
        rewardRatePerSecond = _rewardRatePerSecond;//设置奖励率 这定义了每秒向质押者集体分配多少奖励代币
        owner = msg.sender;//部署合约的人成为所有者。

        // 尝试获取小数位数
        try IERC20Metadata(_stakingToken).decimals() returns (uint8 decimals) {
            stakingTokenDecimals = decimals;
        } catch (bytes memory) {
            stakingTokenDecimals = 18; // 如果获取失败,默认为 18 位小数
        }
    }

    ///     质押代币以开始赚取奖励
    function stake(uint256 amount) external nonReentrant {//nonReentrant 阻止重入攻击
        require(amount > 0, "Cannot stake 0");//:不能质押 0

        updateRewards(msg.sender);//更新待处理奖励

        stakingToken.transferFrom(msg.sender, address(this), amount);//msg.sender 给合约转账
        stakers[msg.sender].stakedAmount += amount;//抵押数量更新

        emit Staked(msg.sender, amount);//公告事件
    }

    ///     取消质押代币并可选择领取奖励
    function unstake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot unstake 0");//取消的数量必须大于0
        require(stakers[msg.sender].stakedAmount >= amount, "Not enough staked");//取消数量需要小于等于现有的抵押数量

        updateRewards(msg.sender);//更新奖励

        stakers[msg.sender].stakedAmount -= amount;//更新抵押币数量
        stakingToken.transfer(msg.sender, amount);//转账

        emit Unstaked(msg.sender, amount);//公告事件
    }

    ///     领取累积的奖励
    function claimRewards() external nonReentrant {
        updateRewards(msg.sender);//更新奖励

        uint256 reward = stakers[msg.sender].rewardDebt;//reward等于剩余还未领取奖励
        require(reward > 0, "No rewards to claim");//剩余奖励需要大于0
        require(rewardToken.balanceOf(address(this)) >= reward, "Insufficient reward token balance");
        //合约token的余额大于奖励

        stakers[msg.sender].rewardDebt = 0;//账本更新0
        rewardToken.transfer(msg.sender, reward);//转账奖励

        emit RewardClaimed(msg.sender, reward);//公告事件
    }

    ///     紧急取消质押而不领取奖励
    function emergencyWithdraw() external nonReentrant {
        uint256 amount = stakers[msg.sender].stakedAmount;
        require(amount > 0, "Nothing staked");

        stakers[msg.sender].stakedAmount = 0;
        stakers[msg.sender].rewardDebt = 0;
        stakers[msg.sender].lastUpdate = block.timestamp;//更新时间戳

        stakingToken.transfer(msg.sender, amount);//转账

        emit EmergencyWithdraw(msg.sender, amount);
    }

    ///     管理员可以补充奖励代币
    function refillRewards(uint256 amount) external onlyOwner {
        rewardToken.transferFrom(msg.sender, address(this), amount);//给合约转移一定数量的代币

        emit RewardRefilled(msg.sender, amount);//公告事件
    }

    ///     更新质押者的奖励
    function updateRewards(address user) internal {
        StakerInfo storage staker = stakers[user];//输入user地址就可以得到用户信息，把值赋给staker

        if (staker.stakedAmount > 0) {//如果用户抵押币大于0
            uint256 timeDiff = block.timestamp - staker.lastUpdate;//奖励时间等于当前时间戳减去上次更新时间
            uint256 rewardMultiplier = 10 ** stakingTokenDecimals;//奖励乘法等于10的小数位次幂
            uint256 pendingReward = (timeDiff * rewardRatePerSecond * staker.stakedAmount) / rewardMultiplier;
            //等待获取的奖励=（时间*每秒获得奖励*抵押币数量）除以小时位
            staker.rewardDebt += pendingReward;//已经赚取但尚未领取的奖励数量更新
        }

        staker.lastUpdate = block.timestamp;//上次更新的时间戳更新
    }

    ///     查看待处理奖励而不领取
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

    ///     查看质押代币小数位数
    function getStakingTokenDecimals() external view returns (uint8) {
        return stakingTokenDecimals;
    }
}

