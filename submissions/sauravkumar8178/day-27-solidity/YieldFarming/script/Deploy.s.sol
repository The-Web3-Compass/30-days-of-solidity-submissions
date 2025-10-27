// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/MockERC20.sol";
import "../src/StakingRewards.sol";

contract DeployScript is Script {
    function run() public {
        vm.startBroadcast();
        // Deploy mock tokens (for demo/dev)
        MockERC20 stake = new MockERC20("Stake Token", "STK", 0);
        MockERC20 reward = new MockERC20("Reward Token", "RWD", 0);

        // Mint some tokens to deployer
        stake.mint(msg.sender, 1_000_000 ether);
        reward.mint(msg.sender, 1_000_000 ether);

        StakingRewards staking = new StakingRewards(address(stake), address(reward));

        // Example: owner (deployer) would approve reward token and call notifyRewardAmount off-chain
        vm.stopBroadcast();
    }
}
