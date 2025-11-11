
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
/**
 * @title SimpleTokenStaking
 * @author Eric (https://github.com/0xxEric)
 * @notice Minimal yield farming contract where users can stake tokens to earn rewards.
 * @dev This is a simplified version for learning and demonstration purposes only.
 */

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address user) external view returns (uint256);
}

contract SimpleTokenStaking {
    IERC20 public stakingToken;   // Token users deposit
    IERC20 public rewardToken;    // Token distributed as rewards

    uint256 public rewardRate;    // Reward per second
    uint256 public lastUpdate;    // Last time rewards were calculated
    uint256 public rewardPerTokenStored;

    uint256 public totalStaked;   // Total staked tokens in pool

    mapping(address => uint256) public stakedBalance; // Each user's staked balance
    mapping(address => uint256) public rewards;       // Accumulated rewards
    mapping(address => uint256) public userRewardPerTokenPaid; // Tracks last rewardPerToken seen by user

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier updateReward(address account) {
        // Update global reward per token
        rewardPerTokenStored = rewardPerToken();
        lastUpdate = block.timestamp;

        // Update user's pending rewards
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(address _stakingToken, address _rewardToken, uint256 _rewardRate) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate;
        owner = msg.sender;
        lastUpdate = block.timestamp;
    }

    /**
     * @notice Stake tokens to earn rewards over time.
     * @param amount The number of tokens to stake.
     */
    function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        totalStaked += amount;
        stakedBalance[msg.sender] += amount;
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    /**
     * @notice Withdraw your staked tokens.
     * @param amount The number of tokens to withdraw.
     */
    function withdraw(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(stakedBalance[msg.sender] >= amount, "Not enough balance");
        totalStaked -= amount;
        stakedBalance[msg.sender] -= amount;
        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
    }

    /**
     * @notice Claim accumulated rewards.
     */
    function claimReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards");
        rewards[msg.sender] = 0;
        require(rewardToken.transfer(msg.sender, reward), "Reward transfer failed");
    }

    /**
     * @notice Calculates the reward per token accumulated up to now.
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) return rewardPerTokenStored;
        uint256 timeDiff = block.timestamp - lastUpdate;
        return rewardPerTokenStored + (timeDiff * rewardRate * 1e18) / totalStaked;
    }

    /**
     * @notice View function to check how many rewards a user has earned.
     */
    function earned(address account) public view returns (uint256) {
        uint256 userBalance = stakedBalance[account];
        uint256 currentRPT = rewardPerToken();
        uint256 rewardDelta = currentRPT - userRewardPerTokenPaid[account];
        return (userBalance * rewardDelta) / 1e18 + rewards[account];
    }

    /**
     * @notice Admin can update the reward rate (tokens distributed per second).
     */
    function setRewardRate(uint256 newRate) external onlyOwner updateReward(address(0)) {
        rewardRate = newRate;
    }

    /**
     * @notice Emergency function: owner can withdraw remaining reward tokens.
     */
    function withdrawRewards(uint256 amount) external onlyOwner {
        require(rewardToken.transfer(owner, amount), "Transfer failed");
    }
}
