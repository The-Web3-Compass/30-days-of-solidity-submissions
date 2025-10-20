// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";

/**
 * @title YieldFarm
 * @author shivam
 * @notice A contract for staking a specific token (stakingToken) to earn rewards in another token (rewardToken).
 * @dev Implements a basic yield farming mechanism where rewards are distributed proportionally to the amount staked over time.
 * Rewards are funded by the contract owner via the `notifyRewardAmount` function.
 */
contract YieldFarm {
    // --- State Variables ---

    /// @notice The address of the ERC20 token users will stake.
    IERC20 public immutable stakingToken;
    /// @notice The address of the ERC20 token users will receive as rewards.
    IERC20 public immutable rewardToken;
    /// @notice The address of the contract owner.
    address public owner;
    /// @notice The total amount of staked tokens.
    uint256 public totalStaked;

    /// @notice Mapping from user address to their staked balance
    mapping(address => uint256) public balances;

    /// @notice The end time of the reward distribution period.
    uint256 public periodFinish;
    /// @notice The reward rate per second.
    uint256 public rewardRate;
    /// @notice The last time the reward distribution was updated.
    uint256 public lastUpdateTime;
    /// @notice The cumulative reward distributed per full token staked.
    uint256 public rewardPerTokenStored;

    // User-specific reward tracking
    /// @notice Mapping from user address to the reward per token paid out
    mapping(address => uint256) public userRewardPerTokenPaid;
    /// @notice Mapping from user address to their earned but unclaimed rewards
    mapping(address => uint256) public rewards;

    // --- Events ---

    /// @notice Emitted when a user stakes tokens
    /// @param user The address of the user
    /// @param amount The amount of tokens staked
    event Staked(address indexed user, uint256 amount);
    
    /// @notice Emitted when a user unstakes tokens
    /// @param user The address of the user
    /// @param amount The amount of tokens unstaked
    event Unstaked(address indexed user, uint256 amount);
    
    /// @notice Emitted when a user claims rewards
    /// @param user The address of the user
    /// @param amount The amount of rewards claimed
    event RewardClaimed(address indexed user, uint256 amount);
    
    /// @notice Emitted when the owner adds rewards to be distributed
    /// @param reward The amount of rewards added
    /// @param duration The duration of the reward distribution period
    event RewardAdded(uint256 reward, uint256 duration);


    // --- Modifiers ---

    /// @notice Modifier to ensure only the contract owner can execute a function.
    modifier onlyOwner() {
        require(msg.sender == owner, "YieldFarm: Caller is not the owner");
        _;
    }

    /// @notice Modifier to update reward variables for a specific account before executing a function.
    /// @dev Ensures reward calculations are based on the latest state.
    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    // --- Constructor ---

    /**
     * @notice Initializes the YieldFarm contract.
     * @param _stakingToken The address of the ERC20 token users will stake.
     * @param _rewardToken The address of the ERC20 token users will receive as rewards.
     */
    constructor(address _stakingToken, address _rewardToken) {
        require(_stakingToken != address(0), "YieldFarm: Staking token cannot be zero address");
        require(_rewardToken != address(0), "YieldFarm: Reward token cannot be zero address");

        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    // --- View Functions (Reward Calculation Helpers) ---

    /**
     * @notice Calculates the last timestamp reward distribution applies to.
     * @dev Returns the minimum of the current block timestamp and the reward period finish time.
     * @return The applicable timestamp.
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /**
     * @notice Calculates the reward per token distributed since the last update.
     * @dev Takes into account the time elapsed and the current reward rate.
     * @return reward cumulative reward distributed per full token staked.
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        uint256 timeElapsed = lastTimeRewardApplicable() - lastUpdateTime;
        // Using 1e18 scaling factor for precision
        return rewardPerTokenStored + (timeElapsed * rewardRate * 1e18 / totalStaked);
    }

    /**
     * @notice Calculates the amount of reward tokens earned by a specific account.
     * @param _account The address of the user.
     * @return The amount of reward tokens earned but not yet claimed.
     */
    function earned(address _account) public view returns (uint256) {
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 userBalance = balances[_account];
        uint256 userPaid = userRewardPerTokenPaid[_account];
        uint256 userRewards = rewards[_account];

        // Calculate new rewards based on the difference in rewardPerToken and scale down
        return userRewards + (userBalance * (currentRewardPerToken - userPaid) / 1e18);
    }

    // --- External Functions (User Actions) ---

    /**
     * @notice Stakes a specified amount of staking tokens.
     * @dev Transfers `amount` of staking tokens from the caller to this contract.
     * Requires prior approval of the staking token for this contract.
     * Updates rewards for the user before staking.
     * @param _amount The amount of staking tokens to stake.
     */
    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "YieldFarm: Cannot stake 0 tokens");
        totalStaked += _amount;
        balances[msg.sender] += _amount;
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "YieldFarm: Staking token transfer failed");
        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice Unstakes a specified amount of staking tokens.
     * @dev Transfers `amount` of staking tokens from this contract back to the caller.
     * Updates rewards for the user before unstaking.
     * @param _amount The amount of staking tokens to unstake.
     */
    function unstake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "YieldFarm: Cannot unstake 0 tokens");
        require(balances[msg.sender] >= _amount, "YieldFarm: Insufficient staked balance");
        totalStaked -= _amount;
        balances[msg.sender] -= _amount;
        require(stakingToken.transfer(msg.sender, _amount), "YieldFarm: Staking token transfer failed");
        emit Unstaked(msg.sender, _amount);
    }

    /**
     * @notice Claims accumulated reward tokens for the caller.
     * @dev Transfers the earned reward tokens to the caller.
     * Updates rewards for the user before claiming.
     */
    function claimReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            require(rewardToken.transfer(msg.sender, reward), "YieldFarm: Reward token transfer failed");
            emit RewardClaimed(msg.sender, reward);
        }
    }

    // --- External Functions (Owner Actions) ---

    /**
     * @notice Called by the owner to add rewards to the contract and set the distribution duration.
     * @dev Transfers `_reward` amount of reward tokens from the caller (owner) to this contract.
     * Requires prior approval of the reward token for this contract by the owner.
     * Calculates the reward rate based on the provided reward amount and duration.
     * @param _reward The total amount of reward tokens to distribute.
     * @param _duration The duration (in seconds) over which the rewards should be distributed.
     */
    function notifyRewardAmount(uint256 _reward, uint256 _duration) external onlyOwner updateReward(address(0)) {
        require(_duration > 0, "YieldFarm: Duration must be greater than 0");
        require(_reward > 0, "YieldFarm: Reward amount must be greater than 0");

        // Ensure reward token transfer succeeds before updating state
        require(rewardToken.transferFrom(msg.sender, address(this), _reward), "YieldFarm: Reward token transfer failed");

        if (block.timestamp >= periodFinish) {
            // If the previous period is finished, start a new one
            rewardRate = _reward / _duration;
        } else {
            // If the previous period is still ongoing, add to the existing rate
            uint256 remainingTime = periodFinish - block.timestamp;
            uint256 leftoverReward = remainingTime * rewardRate;
            rewardRate = (_reward + leftoverReward) / _duration;
        }

        // Ensure reward rate is not zero if reward is non-zero (prevents division error with very small rewards/large duration)
        require(rewardRate > 0 || _reward == 0, "YieldFarm: Calculated reward rate is zero");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + _duration;
        emit RewardAdded(_reward, _duration);
    }

}