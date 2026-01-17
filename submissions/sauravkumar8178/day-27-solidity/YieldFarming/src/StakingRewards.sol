// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title StakingRewards
 * @notice Simple staking rewards contract: stake an ERC20 (stakeToken) and earn another ERC20 (rewardToken).
 * Reward distribution uses rewardPerToken / userRewardPerTokenPaid accounting (scaled by 1e18).
 */
contract StakingRewards is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakeToken;
    IERC20 public immutable rewardToken;

    uint256 public totalSupply;
    mapping(address => uint256) public balances;

    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateTime;
    uint256 public rewardRate; // reward tokens per second
    uint256 private constant PRECISION = 1e18;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);
    event RewardAdded(uint256 reward);

    constructor(address _stakeToken, address _rewardToken) {
        require(_stakeToken != address(0) && _rewardToken != address(0), "zero address");
        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        lastUpdateTime = block.timestamp;
    }

    modifier updateReward(address account) {
        _updateRewardPerToken();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function _updateRewardPerToken() internal {
        if (totalSupply == 0) {
            lastUpdateTime = block.timestamp;
            return;
        }
        uint256 timeDelta = block.timestamp - lastUpdateTime;
        if (timeDelta > 0) {
            uint256 rewardAccrued = timeDelta * rewardRate;
            // rewardPerTokenStored += rewardAccrued * PRECISION / totalSupply
            rewardPerTokenStored += (rewardAccrued * PRECISION) / totalSupply;
            lastUpdateTime = block.timestamp;
        }
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner updateReward(address(0)) {
        emit RewardRateUpdated(rewardRate, _rewardRate);
        rewardRate = _rewardRate;
    }

    /// @notice Owner deposits reward tokens into contract (pull model) then sets rate
    function notifyRewardAmount(uint256 reward, uint256 duration) external onlyOwner updateReward(address(0)) {
        require(duration > 0, "duration>0");
        // transfer reward tokens into contract
        rewardToken.safeTransferFrom(msg.sender, address(this), reward);
        // new rate = reward / duration
        uint256 newRate = reward / duration;
        setRewardRate(newRate);
        emit RewardAdded(reward);
    }

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "amount>0");
        totalSupply += amount;
        balances[msg.sender] += amount;
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "amount>0");
        require(balances[msg.sender] >= amount, "insufficient");
        totalSupply -= amount;
        balances[msg.sender] -= amount;
        stakeToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(balances[msg.sender]);
        getReward();
    }

    function earned(address account) public view returns (uint256) {
        uint256 _balance = balances[account];
        uint256 _rewardPerToken = rewardPerTokenStored;
        if (totalSupply != 0) {
            uint256 timeDelta = block.timestamp - lastUpdateTime;
            // include pending accrual
            uint256 pending = timeDelta * rewardRate;
            _rewardPerToken += (pending * PRECISION) / totalSupply;
        }
        return (_balance * (_rewardPerToken - userRewardPerTokenPaid[account])) / PRECISION + rewards[account];
    }

    // Allow owner to recover tokens accidentally sent to contract (except stakeToken & rewardToken)
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakeToken) && tokenAddress != address(rewardToken), "cannot recover core tokens");
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    }
}
