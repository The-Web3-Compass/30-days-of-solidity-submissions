//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

interface IERC20Metadata is IERC20{
    function decimals() external view returns(uint8);
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
}

contract YieldFarming is ReentrancyGuard{
    using SafeCast for uint256;
    address public owner;
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint256 public rewardRatePerSecond;
    uint8 public stakingTokenDecimals;

    struct StakerInfo{
        uint256 stakeAmount;
        uint256 rewardDebt;
        uint256 lastUpdate;
    }

    mapping(address => StakerInfo) public stakers;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardRefilled(address indexed owner, uint256 amount);

    modifier onlyOwner(){
        require(owner == msg.sender, "Only owner can call this function");
        _;
    }

    constructor(address _stakingToken, address _rewardToken, uint256 _rewardRatePerSecond){
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRatePerSecond = _rewardRatePerSecond;

        try IERC20Metadata(_stakingToken).decimals() returns(uint8 decimals){
            stakingTokenDecimals = decimals;
        }
        catch (bytes memory){
            stakingTokenDecimals = 18;
        }
    }

    function stake(uint256 amount) external nonReentrant{
        require(amount > 0, "Can not stake 0");
        updateRewards(msg.sender);
        stakingToken.transferFrom(msg.sender, address(this), amount);
        stakers[msg.sender].stakeAmount += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant{
        require(amount > 0, "Cannot unstake 0");
        require(stakers[msg.sender].stakeAmount >= amount, "Not enough to unstake");
        updateRewards(msg.sender);
        stakers[msg.sender].stakeAmount -= amount;
        stakingToken.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external nonReentrant{
        updateRewards(msg.sender);
        uint256 reward = stakers[msg.sender].rewardDebt;
        require(reward > 0, "No rewards to claim");
        require(rewardToken.balanceOf(address(this)) >= reward, "Insufficient reward token balance");
        stakers[msg.sender].rewardDebt = 0;
        rewardToken.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function emergencyWithdraw() external nonReentrant{
        uint256 amount = stakers[msg.sender].stakeAmount;
        require(amount > 0, "Nothing staked");
        stakers[msg.sender].stakeAmount = 0;
        stakers[msg.sender].rewardDebt = 0;
        stakers[msg.sender].lastUpdate = block.timestamp;
        stakingToken.transfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }

    function refillRewards(uint256 amount) external onlyOwner{
        rewardToken.transferFrom(msg.sender, address(this), amount);
        emit RewardRefilled(msg.sender, amount);
    }

    function updateRewards(address user) internal{
        StakerInfo storage staker = stakers[user];
        if(staker.stakeAmount > 0){
            uint256 timeDiff = block.timestamp - staker.lastUpdate;
            uint256 rewardMultiplier = 10 ** stakingTokenDecimals;
            uint256 pendingReward = (timeDiff * rewardRatePerSecond * staker.stakeAmount)/rewardMultiplier;
            staker.rewardDebt += pendingReward;
        }
        staker.lastUpdate = block.timestamp;
    }

    function pendingRewards(address user) external view returns(uint256){
        StakerInfo memory staker = stakers[user];
        uint256 pendingReward = staker.rewardDebt;
        if(staker.stakeAmount > 0){
            uint256 timeDiff = block.timestamp - staker.lastUpdate;
            uint256 rewardMultiplier = 10 ** stakingTokenDecimals;
            pendingReward = (timeDiff * rewardRatePerSecond * staker.stakeAmount) / rewardMultiplier;
        }
        return pendingReward;
    }

    function getStakingTokenDecimals() external view returns(uint8){
        return stakingTokenDecimals;
    }
}
