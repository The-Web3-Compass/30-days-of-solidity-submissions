// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FitnessTracker {
    struct Workout {
        string workoutType;
        uint256 duration;
        uint256 calories;
        uint256 timestamp;
    }
    
    struct UserStats {
        uint256 totalWorkouts;
        uint256 totalMinutes;
        uint256 totalCalories;
        uint256 lastWeeklyReset;
        uint256 weeklyWorkouts;
        uint256 weeklyMinutes;
        mapping(uint256 => bool) milestonesAchieved;
    }
    
    mapping(address => UserStats) private userStats;
    mapping(address => Workout[]) private workoutHistory;
    
    // Milestone configuration (could be made configurable)
    uint256 public constant WORKOUTS_PER_WEEK_MILESTONE = 10;
    uint256 public constant MINUTES_TOTAL_MILESTONE = 500;
    
    // Events with indexed parameters for efficient filtering
    event WorkoutLogged(
        address indexed user,
        string workoutType,
        uint256 duration,
        uint256 calories,
        uint256 timestamp
    );
    
    event WeeklyWorkoutMilestone(
        address indexed user,
        uint256 count,
        uint256 weekStart
    );
    
    event TotalMinutesMilestone(
        address indexed user,
        uint256 totalMinutes
    );
    
    // Log a new workout with type, duration, and calories
    function logWorkout(
        string calldata workoutType, 
        uint256 duration, 
        uint256 calories
    ) external {
        require(duration > 0, "Duration must be > 0");
        require(calories > 0, "Calories must be > 0");
        
        UserStats storage stats = userStats[msg.sender];
        
        // Reset weekly stats if it's a new week
        uint256 currentWeek = block.timestamp / 1 weeks;
        if (stats.lastWeeklyReset < currentWeek) {
            stats.weeklyWorkouts = 0;
            stats.weeklyMinutes = 0;
            stats.lastWeeklyReset = currentWeek;
        }
        
        // Update stats
        stats.totalWorkouts++;
        stats.totalMinutes += duration;
        stats.totalCalories += calories;
        stats.weeklyWorkouts++;
        stats.weeklyMinutes += duration;
        
        // Store workout
        workoutHistory[msg.sender].push(Workout({
            workoutType: workoutType,
            duration: duration,
            calories: calories,
            timestamp: block.timestamp
        }));
        
        // Emit workout event
        emit WorkoutLogged(
            msg.sender,
            workoutType,
            duration,
            calories,
            block.timestamp
        );
        
        // Check for weekly workout milestone
        if (stats.weeklyWorkouts == WORKOUTS_PER_WEEK_MILESTONE) {
            emit WeeklyWorkoutMilestone(
                msg.sender,
                WORKOUTS_PER_WEEK_MILESTONE,
                currentWeek * 1 weeks
            );
        }
        
        // Check for total minutes milestone (500, 1000, 1500, etc.)
        uint256 milestoneThreshold = MINUTES_TOTAL_MILESTONE;
        while (stats.totalMinutes >= milestoneThreshold) {
            if (!stats.milestonesAchieved[milestoneThreshold]) {
                stats.milestonesAchieved[milestoneThreshold] = true;
                emit TotalMinutesMilestone(
                    msg.sender,
                    milestoneThreshold
                );
            }
            milestoneThreshold += MINUTES_TOTAL_MILESTONE;
        }
    }
    
    // Get user's workout history
    function getWorkoutHistory() external view returns (Workout[] memory) {
        return workoutHistory[msg.sender];
    }
    
    // Get user's current stats
    function getUserStats() external view returns (
        uint256 totalWorkouts,
        uint256 totalMinutes,
        uint256 totalCalories,
        uint256 weeklyWorkouts,
        uint256 weeklyMinutes
    ) {
        UserStats storage stats = userStats[msg.sender];
        return (
            stats.totalWorkouts,
            stats.totalMinutes,
            stats.totalCalories,
            stats.weeklyWorkouts,
            stats.weeklyMinutes
        );
    }
    
    // Check if user has achieved a specific minutes milestone
    function hasAchievedMinutesMilestone(
        address user, 
        uint256 milestone
    ) external view returns (bool) {
        require(milestone % MINUTES_TOTAL_MILESTONE == 0, 
                "Invalid milestone value");
        return userStats[user].milestonesAchieved[milestone];
    }
}