// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract YieldFarming {

    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public rewardDebt;
    mapping(address => uint256) public lastUpdate;

    uint256 public rewardRate = 1e15; // reward per second per ETH (adjustable)

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    /*
     * Stake ETH
     */
    function stake() external payable {
        require(msg.value > 0, "Send ETH");

        // Update rewards before changing stake
        _updateRewards(msg.sender);

        stakedAmount[msg.sender] += msg.value;
        lastUpdate[msg.sender] = block.timestamp;

        emit Staked(msg.sender, msg.value);
    }

    /*
     * Withdraw staked ETH
     */
    function withdraw(uint256 amount) external {
        require(stakedAmount[msg.sender] >= amount, "Insufficient stake");

        _updateRewards(msg.sender);

        stakedAmount[msg.sender] -= amount;
        lastUpdate[msg.sender] = block.timestamp;

        payable(msg.sender).transfer(amount);

        emit Withdrawn(msg.sender, amount);
    }

    /*
     * Claim rewards
     */
    function claimRewards() external {
        _updateRewards(msg.sender);

        uint256 reward = rewardDebt[msg.sender];
        require(reward > 0, "No rewards");

        rewardDebt[msg.sender] = 0;

        payable(msg.sender).transfer(reward);

        emit RewardClaimed(msg.sender, reward);
    }

    /*
     * Internal reward calculation
     */
    function _updateRewards(address user) internal {
        if (stakedAmount[user] > 0) {
            uint256 timeElapsed = block.timestamp - lastUpdate[user];
            uint256 reward = (stakedAmount[user] * timeElapsed * rewardRate) / 1e18;

            rewardDebt[user] += reward;
        }
        lastUpdate[user] = block.timestamp;
    }

    /*
     * View pending rewards
     */
    function pendingRewards(address user) external view returns (uint256) {
        uint256 reward = rewardDebt[user];

        if (stakedAmount[user] > 0) {
            uint256 timeElapsed = block.timestamp - lastUpdate[user];
            reward += (stakedAmount[user] * timeElapsed * rewardRate) / 1e18;
        }

        return reward;
    }
}