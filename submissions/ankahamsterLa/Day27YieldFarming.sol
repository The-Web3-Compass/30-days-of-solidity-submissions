//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// Build a yielding farming platform.
// Build a fair,secure,time-weighted reward system that keeps the DeFi ecosystem running.
// Lock tokens up for a while and grow more tokens as a reward.

// This contract shows you how to:
// Track individual user stakes properly;
// Calculate dynamic rewards over time;
// Build emergency exit options for users;
// Manage reward funds without breaking the system.

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// In solidity, when handle with data of different types like downcast numbers without checking, the data would overflow or trunate values without realizing it.
// When dealing with some number involving token decimals, it can make sure that casting number safely.
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Extension for the standard "IERC20" interface.
interface IERC20Metadata is IERC20{
    function decimals() external view returns(uint8);
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
}

contract YieldFarming is ReentrancyGuard{
    // This line is a solidity trick --- it extends the native "uint256" type with new safe functions from the "SafeCast" library.
    // Mainly used in handling different reward scales, managing decimals and doing precise reward calculations.
    using SafeCast for uint256;

    // This is the token that users will stake into the contract.
    IERC20 public stakingToken;
    // This is the token that users will earn as rewards.
    IERC20 public rewardToken;

    // This defines how fast rewards are generated.
    uint256 public rewardRatePerSecond;

    // Ability of owner in this contract:
    // Refilling the reward pool.
    // Updating in more advanced versions.
    address public owner;
    
    uint8 public stakingTokenDecimals;

    struct StakerInfo{
        uint256 stakedAmount;
        uint256 rewardDebt; // This keeps track of how much reward the user has already earned but not yet claimed.
        uint256 lastUpdate;
    }

    mapping(address=>StakerInfo) public stakers;

    event Staked(address indexed user,uint256 amount);
    event Unstaked(address indexed user,uint256 amount);
    event RewardClaimed(address indexed user,uint256 amount);
    // Triggered when a user pulls out their stake immediately without waiting for rewards.
    event EmergencyWithdraw(address indexed user,uint256 amount);
    // It tells that who refilled and how many tokens were added to the pool.
    event RewardRefilled(address indexed owner,uint256 amount);

    modifier onlyOwner(){
        require(msg.sender==owner,"Not the owner");
        _;
    }

    constructor(address _stakingToken,address _rewardToken,uint256 _rewardRatePerSecond){
        stakingToken=IERC20(_stakingToken);
        rewardToken=IERC20(_rewardToken);
        rewardRatePerSecond=_rewardRatePerSecond;
        owner=msg.sender;

        // Get staking token decimals
        // Some tokens especially the non-standard ones might not can implement this function, so wrap in "try/catch"
        try IERC20Metadata(_stakingToken).decimals() returns (uint8 decimals){
            stakingTokenDecimals=decimals;
        }catch(bytes memory){
            stakingTokenDecimals=18;
        }
    }

    // A user sends some tokens into the contract and start earning rewards second by second.
    function stake(uint256 amount) external nonReentrant{
        require(amount>0,"Cannot stake 0");
        updateRewards(msg.sender);
        // Transfer the staking tokens from the user's wallet into the contract.
        stakingToken.transferFrom(msg.sender,address(this),amount);
        stakers[msg.sender].stakedAmount+=amount;
        emit Staked(msg.sender,amount);

    }

    // Safely withdraw staked tokens and update the rewards.
    function unstake(uint256 amount) external nonReentrant{
        require(amount>0,"Cannot unstake 0");
        require(stakers[msg.sender].stakedAmount>=amount,"Not enough staked");
        updateRewards(msg.sender);

        stakers[msg.sender].stakedAmount-=amount;
        stakingToken.transfer(msg.sender,amount);
        emit Unstaked(msg.sender,amount);
    }

    // Withdraw user's earned tokens without touching their original stake.
    function claimRewards() external nonReentrant{
        // When running this function, it would update the information of "stakers[msg.sender]"
        updateRewards(msg.sender);

        uint256 reward=stakers[msg.sender].rewardDebt;
        require(reward>0,"No rewards to claim");
        require(rewardToken.balanceOf(address(this))>=reward,"Insufficient reward token balance");

        stakers[msg.sender].rewardDebt=0;
        rewardToken.transfer(msg.sender,reward);

        emit RewardClaimed(msg.sender,reward);
    }

    // Get tokens back instantly and give up the rewards.
    function emergencyWithdraw() external nonReentrant{
        uint256 amount=stakers[msg.sender].stakedAmount;
        require(amount>0,"Nothing staked");

        stakers[msg.sender].stakedAmount=0;
        stakers[msg.sender].rewardDebt=0;
        stakers[msg.sender].lastUpdate=block.timestamp;

        stakingToken.transfer(msg.sender,amount);
        emit EmergencyWithdraw(msg.sender,amount);
    }

    // The admin/owner can simply top up the reward pool.
    function refillRewards(uint256 amount) external onlyOwner{
        rewardToken.transferFrom(msg.sender,address(this),amount);
        emit RewardRefilled(msg.sender,amount);
    }

    function updateRewards(address user) internal{
        StakerInfo storage staker=stakers[user];

        if(staker.stakedAmount>0){
            uint256 timeDiff=block.timestamp-staker.lastUpdate;
            uint256 rewardMultiplier=10**stakingTokenDecimals;
            uint256 pendingReward=(timeDiff*rewardRatePerSecond*staker.stakedAmount)/rewardMultiplier;
            staker.rewardDebt+=pendingReward;
        }
        staker.lastUpdate=block.timestamp;
    }

    function pendingRewards(address user) external view returns(uint256){
        StakerInfo memory staker=stakers[user];
        uint256 pendingReward=staker.rewardDebt;
        if(staker.stakedAmount>0){
            uint256 timeDiff=block.timestamp-staker.lastUpdate;
            uint256 rewardMultiplier=10**stakingTokenDecimals;
            pendingReward=(timeDiff*rewardRatePerSecond*staker.stakedAmount)/rewardMultiplier;

        }
        return pendingReward;
    }

    function getStakingTokenDecimals() external view returns(uint8){
        return stakingTokenDecimals;

    }

}

