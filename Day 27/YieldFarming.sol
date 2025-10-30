// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title YieldFarming
 * @dev A simple yield farming contract where users stake tokens to earn rewards over time.
 * Rewards are distributed based on staking duration and amount.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YieldFarming is Ownable {
    IERC20 public stakingToken;      // Token that users stake
    IERC20 public rewardToken;       // Token that users earn as rewards

    uint256 public rewardRate;       // Reward rate per second
    uint256 public totalStaked;      // Total tokens staked in the contract

    struct StakeInfo {
        uint256 amount;              // Amount of tokens staked
        uint256 rewardDebt;          // Rewards already claimed
        uint256 lastUpdated;         // Last update timestamp
    }

    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardRate
    ) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate; // e.g., tokens per second per staked token
    }

    /**
     * @dev Stake tokens to start earning rewards
     */
    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0 tokens");

        _updateReward(msg.sender);

        stakingToken.transferFrom(msg.sender, address(this), _amount);
        stakes[msg.sender].amount += _amount;
        totalStaked += _amount;

        emit Staked(msg.sender, _amount);
    }

    /**
     * @dev Withdraw staked tokens
     */
    function unstake(uint256 _amount) external {
        StakeInfo storage user = stakes[msg.sender];
        require(user.amount >= _amount, "Insufficient staked balance");

        _updateReward(msg.sender);

        user.amount -= _amount;
        totalStaked -= _amount;
        stakingToken.transfer(msg.sender, _amount);

        emit Unstaked(msg.sender, _amount);
    }

    /**
     * @dev Claim accumulated rewards
     */
    function claimRewards() external {
        _updateReward(msg.sender);

        uint256 pending = _calculateReward(msg.sender);
        require(pending > 0, "No rewards to claim");

        stakes[msg.sender].rewardDebt += pending;
        rewardToken.transfer(msg.sender, pending);

        emit RewardClaimed(msg.sender, pending);
    }

    /**
     * @dev Internal function to update user's reward state
     */
    function _updateReward(address _user) internal {
        StakeInfo storage user = stakes[_user];
        if (user.amount > 0) {
            uint256 reward = _calculateReward(_user);
            user.rewardDebt += reward;
        }
        user.lastUpdated = block.timestamp;
    }

    /**
     * @dev Calculate pending reward for a user
     */
    function _calculateReward(address _user) internal view returns (uint256) {
        StakeInfo memory user = stakes[_user];
        if (user.amount == 0) return 0;

        uint256 timeElapsed = block.timestamp - user.lastUpdated;
        uint256 reward = (user.amount * rewardRate * timeElapsed) / 1e18;

        return reward;
    }

    /**
     * @dev Owner can update reward rate
     */
    function updateRewardRate(uint256 _newRate) external onlyOwner {
        rewardRate = _newRate;
    }

    /**
     * @dev Emergency withdraw (without rewards)
     */
    function emergencyWithdraw() external {
        StakeInfo storage user = stakes[msg.sender];
        uint256 staked = user.amount;
        require(staked > 0, "Nothing to withdraw");

        user.amount = 0;
        totalStaked -= staked;
        stakingToken.transfer(msg.sender, staked);

        emit Unstaked(msg.sender, staked);
    }
}
