// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ActivityTracker.sol";

contract ActivityTrackerTest is Test {
    ActivityTracker tracker;
    address user1 = address(0x123);

    function setUp() public {
        tracker = new ActivityTracker();
    }

    function testLogWorkout() public {
        vm.startPrank(user1);
        tracker.logWorkout("Running", 60, 300);
        vm.stopPrank();

        ActivityTracker.Workout[] memory workouts = tracker.getUserWorkouts(user1);
        assertEq(workouts.length, 1);
        assertEq(workouts[0].duration, 60);
        assertEq(tracker.totalDuration(user1), 60);
    }

    function testGoalEvents() public {
        vm.startPrank(user1);
        for (uint256 i = 0; i < 10; i++) {
            tracker.logWorkout("Pushups", 50, 100);
        }
        vm.stopPrank();

        assertEq(tracker.totalWorkouts(user1), 10);
        assertTrue(tracker.totalDuration(user1) >= 500);
    }
}
