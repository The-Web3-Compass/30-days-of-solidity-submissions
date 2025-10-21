// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";

contract YieldFarm {
    // Tokens and owner
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;
    address public owner;

    uint256 public totalStaked;

    mapping(address => uint256) public balances;

    // Reward calculation state
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    // User reward tracking
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    // Events
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardAdded(uint256 reward, uint256 duration);

    // Only owner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Update reward modifier for user
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(address _stakingToken, address _rewardToken) {
        require(_stakingToken != address(0) && _rewardToken != address(0), "Zero address");
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) return rewardPerTokenStored;
        uint256 timeElapsed = lastTimeRewardApplicable() - lastUpdateTime;
        return rewardPerTokenStored + (timeElapsed * rewardRate * 1e18 / totalStaked);
    }

    function earned(address account) public view returns (uint256) {
        uint256 currentRewardPerToken = rewardPerToken();
        return rewards[account] + (balances[account] * (currentRewardPerToken - userRewardPerTokenPaid[account]) / 1e18);
    }

    function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        totalStaked += amount;
        balances[msg.sender] += amount;
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Stake transfer failed");
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot unstake 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        totalStaked -= amount;
        balances[msg.sender] -= amount;
        require(stakingToken.transfer(msg.sender, amount), "Unstake transfer failed");
        emit Unstaked(msg.sender, amount);
    }

    function claimReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            require(rewardToken.transfer(msg.sender, reward), "Reward transfer failed");
            emit RewardClaimed(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward, uint256 duration) external onlyOwner updateReward(address(0)) {
        require(duration > 0 && reward > 0, "Invalid duration or reward");
        require(rewardToken.transferFrom(msg.sender, address(this), reward), "Reward transfer failed");

        if (block.timestamp >= periodFinish) {
            rewardRate = reward / duration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / duration;
        }

        require(rewardRate > 0 || reward == 0, "Reward rate zero");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;
        emit RewardAdded(reward, duration);
    }
}
