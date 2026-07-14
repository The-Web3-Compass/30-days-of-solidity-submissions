// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal IERC20 Interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// Minimal ReentrancyGuard
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract YieldFarming is ReentrancyGuard {
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint256 public rewardRatePerSecond;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakeTimestamp;
    mapping(address => uint256) private savedRewards;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(address _stakingToken, address _rewardToken, uint256 _rewardRatePerSecond) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRatePerSecond = _rewardRatePerSecond;
    }

    modifier updateReward(address account) {
        if (stakedBalance[account] > 0) {
            savedRewards[account] += calculateReward(account);
        }
        stakeTimestamp[account] = block.timestamp;
        _;
    }

    function calculateReward(address user) public view returns (uint256) {
        if (stakedBalance[user] == 0) return 0;
        uint256 timeStaked = block.timestamp - stakeTimestamp[user];
        uint256 stakedAmount = stakedBalance[user];
        return (stakedAmount * timeStaked * rewardRatePerSecond) / 1e18;
    }

    function pendingReward(address user) public view returns (uint256) {
        return savedRewards[user] + calculateReward(user);
    }

    function calculateAPY() public view returns (uint256) {
        uint256 yearlyReward = rewardRatePerSecond * 365 days;
        uint256 totalStaked = stakingToken.balanceOf(address(this));
        if (totalStaked == 0) return 0;
        return (yearlyReward * 100) / totalStaked;
    }

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        stakingToken.transferFrom(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot unstake 0");
        require(stakedBalance[msg.sender] >= amount, "Insufficient staked balance");
        stakedBalance[msg.sender] -= amount;
        stakingToken.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external nonReentrant updateReward(msg.sender) {
        uint256 reward = savedRewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        savedRewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function emergencyWithdraw() external nonReentrant {
        uint256 stakedAmount = stakedBalance[msg.sender];
        require(stakedAmount > 0, "Nothing to withdraw");
        
        stakedBalance[msg.sender] = 0;
        savedRewards[msg.sender] = 0; // Lose all accumulated rewards
        stakeTimestamp[msg.sender] = 0;

        stakingToken.transfer(msg.sender, stakedAmount);
        emit EmergencyWithdraw(msg.sender, stakedAmount);
    }
}
