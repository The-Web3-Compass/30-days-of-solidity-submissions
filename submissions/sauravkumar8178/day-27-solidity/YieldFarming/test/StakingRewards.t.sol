// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/MockERC20.sol";
import "../src/StakingRewards.sol";

contract StakingRewardsTest is Test {
    MockERC20 stake;
    MockERC20 reward;
    StakingRewards staking;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        stake = new MockERC20("Stake Token", "STK", 0);
        reward = new MockERC20("Reward Token", "RWD", 0);

        // fund test accounts
        stake.mint(alice, 1_000 ether);
        stake.mint(bob, 1_000 ether);
        reward.mint(address(this), 10_000 ether);

        staking = new StakingRewards(address(stake), address(reward));

        // approve contract to move rewards when calling notifyRewardAmount
        reward.approve(address(staking), type(uint256).max);
    }

    function testSingleStakerEarnsRewards() public {
        // owner not needed for this test; we'll call notifyRewardAmount from this contract which is owner in this context
        uint256 rewardAmount = 1_000 ether;
        uint256 duration = 100; // seconds
        staking.notifyRewardAmount(rewardAmount, duration);

        // alice stakes 100 tokens
        vm.prank(alice);
        stake.approve(address(staking), 100 ether);
        vm.prank(alice);
        staking.stake(100 ether);

        // advance 50 seconds
        vm.warp(block.timestamp + 50);

        // earned should be approximately rewardAmount * (50/100) = 500 (since alice has all stake)
        uint256 earned = staking.earned(alice);
        assertApproxEqRel(earned, 500 ether, 1e16); // 0.01% relative tolerance

        // claim
        vm.prank(alice);
        staking.getReward();
        uint256 balanceAfter = reward.balanceOf(alice);
        assert(balanceAfter > 499 ether);
    }

    function testMultipleStakersSplitRewards() public {
        uint256 rewardAmount = 1_000 ether;
        uint256 duration = 100; // seconds
        staking.notifyRewardAmount(rewardAmount, duration);

        // alice stakes 100, bob stakes 300
        vm.prank(alice);
        stake.approve(address(staking), 200 ether);
        vm.prank(bob);
        stake.approve(address(staking), 400 ether);

        vm.prank(alice);
        staking.stake(100 ether);

        vm.prank(bob);
        staking.stake(300 ether);

        // advance full duration
        vm.warp(block.timestamp + 100);

        // alice share = 100/(100+300)=0.25 -> 250 reward
        // bob share = 0.75 -> 750 reward
        uint256 aliceEarned = staking.earned(alice);
        uint256 bobEarned = staking.earned(bob);

        assertApproxEqRel(aliceEarned, 250 ether, 1e16);
        assertApproxEqRel(bobEarned, 750 ether, 1e16);
    }
}
