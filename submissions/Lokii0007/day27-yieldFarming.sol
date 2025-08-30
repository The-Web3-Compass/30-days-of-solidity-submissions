// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20Metadata is IERC20 {
    function decimals() external view returns(uint);
    function symbol() external view returns(string memory);
    function name() external view returns(string memory);
}

contract YieldFarming is ReentrancyGuard {
    using SafeCast for uint256;
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint256 public rewardRatePerSecond;
    address public owner;
    uint8 public stakingTokenDecimals;

    struct stakeInfo{
        uint stakeAmount;
        uint rewardDebt;
        uint lastUpdate;
    }

    mapping (address => stakeInfo) public stakers;

    event Staked(address indexed user, uint indexed amount);
    event UnStaked(address indexed user, uint indexed amount);
    event EmergencyWithdraw(address indexed user, uint indexed amount);
    event RewardClaimed(address indexed user, uint indexed amount);
    event RewardFilled(address indexed user, uint indexed amount);

    modifier onlyOwner(){
        require(owner == msg.sender, "only owner is allowed");
        _;
    }

    constructor(address _stakingToken, address _rewardToken, uint _rewardRatePerSecond){
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRatePerSecond = _rewardRatePerSecond;

        try IERC20Metadata(_stakingToken).decimals() returns (uint decimals){
            stakingTokenDecimals = SafeCast.toUint8(decimals);
        }catch(bytes memory){
            stakingTokenDecimals = 18;
        }
    }

    function updateRewards(address _user) internal {
        stakeInfo storage staker = stakers[_user];
        if(staker.stakeAmount > 0){
           uint timeDiff = block.timestamp - staker.lastUpdate;
           uint rewardMultiplier = 10 ** stakingTokenDecimals;
           uint pendingReward = (timeDiff * rewardRatePerSecond * staker.stakeAmount )/rewardMultiplier;
           staker.rewardDebt += pendingReward;
        }

        staker.lastUpdate = block.timestamp;
    }

    function stake(uint _amount) external nonReentrant {
        require(_amount > 0, "amoint must be greater than 0");
        updateRewards(msg.sender);
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        stakers[msg.sender].stakeAmount += _amount;

        emit Staked(msg.sender, _amount);
    }

    function unstake(uint _amount) external nonReentrant {
        require(_amount > 0, "amoint must be greater than 0");
        require( stakers[msg.sender].stakeAmount >= _amount, "not enough balance");
        updateRewards(msg.sender);
        stakers[msg.sender].stakeAmount -= _amount;
        stakingToken.transfer(msg.sender, _amount);

        emit UnStaked(msg.sender, _amount);
    }

    function claimRewards() external nonReentrant{
        updateRewards(msg.sender);
        uint reward = stakers[msg.sender].rewardDebt;
        require(reward > 0, "no rewards to claim");
        require(rewardToken.balanceOf(address(this)) >= reward,"insufficient reward token balance" );
        stakers[msg.sender].rewardDebt = 0;
        rewardToken.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function emergencyWithdraw() external nonReentrant {
        uint amount = stakers[msg.sender].stakeAmount;
        require(amount > 0, "nothing claimed");
        stakers[msg.sender].stakeAmount = 0;
        stakers[msg.sender].rewardDebt = 0;
        stakers[msg.sender].lastUpdate = block.timestamp;

        stakingToken.transfer(msg.sender, amount);

        emit EmergencyWithdraw(msg.sender, amount);
    }

    function refillRewards(uint _amount) external onlyOwner(){
       rewardToken.transferFrom(msg.sender, address(this), _amount);
       emit RewardFilled(msg.sender, _amount);
    }
}