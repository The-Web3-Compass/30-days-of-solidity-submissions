//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


//引入 OpenZeppelin 提供的 ERC20 接口定义
//使本合约能与标准 ERC20 代币进行交互
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//引入防止重入攻击的安全模块
//防止函数在执行过程中被恶意重复调用（如多次提款）
//该模块提供修饰符 nonReentrant ，它会使用内部状态锁定，防止嵌套调用
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//引入安全类型转换库
//使大整数向小整数类型转换时自动检查是否溢出
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

//定义一个扩展的接口 IERC20Metadata，继承自 IERC20
//使本合约能读取代币的额外信息（名称、符号、小数位）
interface IERC20Metadata is IERC20 {
    //声明一个返回代币小数位的函数
    function decimals() external view returns (uint8);
    //返回代币的名称
    function name() external view returns (string memory);
    //返回代币符号
    function symbol() external view returns (string memory);
}

//定义主合约 YieldFarming，并继承 ReentrancyGuard
//创建一个收益农场合约，拥有防重入保护机制
contract YieldFarming is ReentrancyGuard {

    //让 uint256 类型可以直接使用 SafeCast 库中的函数
    using SafeCast for uint256;
    
    //声明一个 ERC20 接口变量，用于存放抵押（Stake）代币
    IERC20 public stakingToken;
    //声明奖励代币接口变量
    IERC20 public rewardToken;

    //定义一个每秒奖励发放速率的状态变量
    uint256 public rewardRatePerSecond; // Rewards distributed per second

    //定义一个地址类型变量 owner，存储合约管理员的地址
    address public owner;
    
    //存储抵押代币的小数位数
    uint8 public stakingTokenDecimals; 

    //定义一个结构体 StakerInfo，用于存储单个用户的质押信息
    struct StakerInfo {
        //记录每位用户的质押总额
        uint256 stakedAmount;
        //用户当前累计但未提取的奖励
        uint256 rewardDebt;
        //计算从上次结算到现在的奖励累积时间
        uint256 lastUpdate;
    }

    //定义一个从地址到结构体的映射
    //存储每个用户的质押状态（金额、奖励、时间）
    mapping(address => StakerInfo) public stakers;

    //声明一个事件，用于记录质押行为
    event Staked(address indexed user, uint256 amount);
    //声明取消质押（取回代币）的事件
    event Unstaked(address indexed user, uint256 amount);
    //声明用户领取奖励时触发的事件
    event RewardClaimed(address indexed user, uint256 amount);
    //声明紧急取回质押资金的事件
    event EmergencyWithdraw(address indexed user, uint256 amount);
    //声明管理员补充奖励资金时的事件
    event RewardRefilled(address indexed owner, uint256 amount);

    //限制函数只能由合约所有者（管理员）调用
    //modifier 是 Solidity 的关键字，用于在函数执行前后插入特定逻辑
    modifier onlyOwner() {
        //检查当前调用者是否为合约所有者
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    constructor(
        //指定用户将要质押的 ERC20 合约
        address _stakingToken,
        //指定用于奖励分发的 ERC20 合约
        address _rewardToken,
        //指定每秒钟发放多少奖励代币
        uint256 _rewardRatePerSecond
    ) {
        //将传入的抵押代币地址绑定到 IERC20 接口实例
        //让合约能通过接口与外部代币交互
        stakingToken = IERC20(_stakingToken);
        //将奖励代币地址绑定到接口
        //使合约可以通过接口操作奖励代币（如转账）
        rewardToken = IERC20(_rewardToken);
        //设置每秒奖励速率
        //将部署时传入的速率存入状态变量，供后续计算奖励使用
        rewardRatePerSecond = _rewardRatePerSecond;
        //标记谁是合约管理员
        owner = msg.sender;

        //使用 try/catch 语句尝试获取抵押代币的小数位数
        // try ... returns (...) {}：用于捕获可能失败的外部调用
        try IERC20Metadata(_stakingToken).decimals() returns (uint8 decimals) {
            //如果成功获取小数位数，则存入状态变量 stakingTokenDecimals
            stakingTokenDecimals = decimals;
        //若代币未实现 decimals() 或调用失败，则执行备用逻辑
        } catch (bytes memory) {
            //当无法获取精度时，默认设为 18
            stakingTokenDecimals = 18; 
        }
    }

    //定义一个外部可调用函数 stake，参数为 amount（质押数量）
    //允许用户将指定数量的抵押代币存入合约，以开始获得奖励
    function stake(uint256 amount) external nonReentrant {
        //检查质押数量是否大于 0
        require(amount > 0, "Cannot stake 0");

        //调用内部函数 updateRewards，更新该用户的奖励数据
        updateRewards(msg.sender);

        //从用户地址向合约地址转入指定数量的质押代币
        //transferFrom(from, to, value)：ERC20 标准函数，用于授权后转账
        stakingToken.transferFrom(msg.sender, address(this), amount);
        //在映射 stakes 中记录用户新的质押总额
        stakers[msg.sender].stakedAmount += amount;

        //触发 Staked 事件，向区块链日志记录这次质押行为
        emit Staked(msg.sender, amount);
    }

    //允许用户从合约中取回部分或全部质押代币
    function unstake(uint256 amount) external nonReentrant {
        //确认提取数量大于 0
        require(amount > 0, "Cannot unstake 0");
        //检查用户质押余额是否足够
        require(stakers[msg.sender].stakedAmount >= amount, "Not enough staked");

        //更新用户奖励记录
        updateRewards(msg.sender);

        //从用户质押余额中减去提取数量
        stakers[msg.sender].stakedAmount -= amount;
        //将质押代币从合约转回给用户
        stakingToken.transfer(msg.sender, amount);

        //触发 Unstaked 事件，记录提取行为
        emit Unstaked(msg.sender, amount);
    }

    //允许用户提取已累计的奖励代币
    function claimRewards() external nonReentrant {
        //更新当前用户的奖励状态
        updateRewards(msg.sender);
        
        //从映射中读取当前用户累计的奖励金额
        //临时保存待发放的奖励数量
        uint256 reward = stakers[msg.sender].rewardDebt;
        //检查用户是否有可领取的奖励
        require(reward > 0, "No rewards to claim");
        //检查合约当前持有的奖励代币余额是否足够支付本次领取
        require(rewardToken.balanceOf(address(this)) >= reward, "Insufficient reward token balance");

        //将该用户的奖励余额清零
        stakers[msg.sender].rewardDebt = 0;
        //将奖励代币发送给用户，完成奖励领取操作
        rewardToken.transfer(msg.sender, reward);
        
        //触发 RewardClaimed 事件，将用户和奖励金额记录到区块链日志中
        emit RewardClaimed(msg.sender, reward);
    }

    //允许用户在紧急情况下提取质押代币，但不领取奖励
    function emergencyWithdraw() external nonReentrant {
        //读取当前用户的质押数量
        uint256 amount = stakers[msg.sender].stakedAmount;
        //验证用户是否确实有质押过代币
        require(amount > 0, "Nothing staked");

        //清空该用户的质押余额，解除质押状态
        stakers[msg.sender].stakedAmount = 0;
        //把该用户的待领奖励清零（用户放弃奖励）
        stakers[msg.sender].rewardDebt = 0;
        //将用户的 lastUpdate 更新为当前区块时间戳
        stakers[msg.sender].lastUpdate = block.timestamp;

        //将质押的代币返还给用户
        stakingToken.transfer(msg.sender, amount);

        //触发 EmergencyWithdraw 事件，记录紧急提取行为供区块链追踪
        emit EmergencyWithdraw(msg.sender, amount);
    }

    //用于管理员补充奖励池中的奖励代币
    function refillRewards(uint256 amount) external onlyOwner {
        //从管理员账户转入指定数量的奖励代币至合约
        //补充奖励池，确保后续用户可领取
        rewardToken.transferFrom(msg.sender, address(this), amount);

        //触发 RewardRefilled 事件，记录管理员补充奖励代币的行为
        emit RewardRefilled(msg.sender, amount);
    }

    //定义内部函数 updateRewards，用于计算和更新用户奖励数据
    function updateRewards(address user) internal {
        //在栈上创建对存储中 stakers[user] 的引用变量 staker
        StakerInfo storage staker = stakers[user];

        //检查该用户是否有质押代币
        if (staker.stakedAmount > 0) {
            //计算自用户上次更新（lastUpdate）至当前的时间差（秒）
            uint256 timeDiff = block.timestamp - staker.lastUpdate;
            //计算基于质押代币小数位的缩放因子
            //10 ** stakingTokenDecimals 为指数运算，结果为 uint256
            uint256 rewardMultiplier = 10 ** stakingTokenDecimals;
            //计算用户自上次更新时间以来应获得的奖励总额
            uint256 pendingReward = (timeDiff * rewardRatePerSecond * staker.stakedAmount) / rewardMultiplier;
            //将计算出的 pendingReward 累加到用户的 rewardDebt（待领取奖励）
            staker.rewardDebt += pendingReward;
        }

        //将该用户的上次更新时间设为当前区块时间
        staker.lastUpdate = block.timestamp;
    }

    //定义一个外部可读的只读函数，返回某用户当前可领取的奖励（包括还未写入 rewardDebt 的那部分）
    function pendingRewards(address user) external view returns (uint256) {
        //把该用户的 StakerInfo 从存储复制到内存变量 staker
        StakerInfo memory staker = stakers[user];
        
        //初始化 pendingReward 为该用户已累积但已写入 rewardDebt 的部分
        //作为返回值计算的基础
        uint256 pendingReward = staker.rewardDebt;

        //若用户当前有质押，则计算从 lastUpdate 到现在的新增奖励并加入返回值
        if (staker.stakedAmount > 0) {
            //计算从上一次更新到现在经过的秒数（同 updateRewards 中的时间差）
            uint256 timeDiff = block.timestamp - staker.lastUpdate;
            //同样计算缩放因子（用于标准化精度）
            uint256 rewardMultiplier = 10 ** stakingTokenDecimals;
            //将这段时间产生的奖励加到 pendingReward 上
            pendingReward += (timeDiff * rewardRatePerSecond * staker.stakedAmount) / rewardMultiplier;
        }

        //返回计算得到的待领取奖励总额（rewardDebt + 现在即时累积）
        return pendingReward;
    }

    //便于外部查询合约记录的抵押代币精度
    function getStakingTokenDecimals() external view returns (uint8) {
        //返回保存在合约中的小数位数值
        return stakingTokenDecimals;
    }
}

