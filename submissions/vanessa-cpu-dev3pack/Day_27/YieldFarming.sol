// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract YieldFarming is ReentrancyGuard {
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    IERC20 public rewardRatePerSecond;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakeTimestamp;
    mapping(address => uint256) public rewards;

    constructor(address _stakingToken, address _rewardToken, uint256 _rewardRate) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRatePerSecond = _rewardRate;
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");

        // Update rewards before changing balance
        updateReward(msg.sender);

        stakingToken.transferFrom(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
        stakedTimestamp[msg.sender] = block.timestamp;
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(stakedBalance[msg.sender] >= amount, "Insufficient balance");

        // Update rewards before changing balance
        updateReward(msg.sender);

        stakedBalance[msg.sender] -= amount;
        stakingToken.transfer(msg.sender, amount);
    }

    function claimRewards() external nonReentrant {
        updateReward(msg.sender);

        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        rewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, reward);
    }

    function updateReward(address user) internal {
        uint256 earned = calculatReward(user);
        rewards[user] += earned;
        stakeTimestamp[user] = block.timestamp;
    }

    function calculatorReward(address user) public view returns (uint256) {
        uint256 timeStaked = block.timestamp - stakeTimestamp[user];
        uint256 stakedAmount = stakedBalance[user];
        return (stakedAmount * rewardRatePerSecond) / 1e18;
    }
}