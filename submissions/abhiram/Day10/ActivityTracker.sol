// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title ActivityTracker
 * @dev A contract to log workouts and track user activity statistics.
 * Users can log workouts, and the contract maintains statistics such as total workouts,
 * total minutes, and total calories burned. It also emits events when users reach certain milestones.
 */
contract ActivityTracker {
    // Workout structure to hold individual workout details
	struct Workout {
		string workoutType;
		uint256 duration; // in minutes
		uint256 calories;
		uint256 timestamp;
	}

    // User statistics structure 
	struct UserStats {
		uint256 totalWorkouts;
		uint256 totalMinutes;
		uint256 totalCalories;
		mapping(uint256 => uint256) weeklyWorkouts; // week => count
	}

    // Mappings to store user workouts and statistics
	mapping(address => Workout[]) private userWorkouts;
	mapping(address => UserStats) private userStats;

    // Events to log significant actions
	event WorkoutLogged(address indexed user, string workoutType, uint256 duration, uint256 calories, uint256 timestamp);
	event WeeklyGoalReached(address indexed user, uint256 indexed week, uint256 workouts);
	event TotalMinutesGoalReached(address indexed user, uint256 totalMinutes);

    // Goals to track user achievements
	uint256 public constant WEEKLY_GOAL = 10;
	uint256 public constant MINUTES_GOAL = 500;

    /**
     * @dev Logs a workout for the sender and updates their statistics.
     * Emits `WorkoutLogged` event. If the user reaches weekly or total minutes goals,
     * emits `WeeklyGoalReached` or `TotalMinutesGoalReached` events respectively.
     * @param _workoutType Type of the workout (e.g., "Running", "Cycling").
     * @param _duration Duration of the workout in minutes.
     * @param _calories Calories burned during the workout.
     */
	function logWorkout(string calldata _workoutType, uint256 _duration, uint256 _calories) external {
		require(_duration > 0, "Duration must be positive");
		require(bytes(_workoutType).length > 0, "Workout type required");

		uint256 week = getWeek(block.timestamp);

		userWorkouts[msg.sender].push(Workout({
			workoutType: _workoutType,
			duration: _duration,
			calories: _calories,
			timestamp: block.timestamp
		}));

		UserStats storage stats = userStats[msg.sender];
		stats.totalWorkouts += 1;
		stats.totalMinutes += _duration;
		stats.totalCalories += _calories;
		stats.weeklyWorkouts[week] += 1;

		emit WorkoutLogged(msg.sender, _workoutType, _duration, _calories, block.timestamp);

		// Check for weekly goal
		if (stats.weeklyWorkouts[week] == WEEKLY_GOAL) {
			emit WeeklyGoalReached(msg.sender, week, WEEKLY_GOAL);
		}
		// Check for total minutes goal
		if (stats.totalMinutes >= MINUTES_GOAL && stats.totalMinutes - _duration < MINUTES_GOAL) {
			emit TotalMinutesGoalReached(msg.sender, stats.totalMinutes);
		}
	}

    // View functions to retrieve user data
	function getUserWorkouts(address user) external view returns (Workout[] memory) {
		return userWorkouts[user];
	}

    // Returns total workouts, total minutes, and total calories for a user
	function getUserStats(address user) external view returns (uint256 totalWorkouts, uint256 totalMinutes, uint256 totalCalories) {
		UserStats storage stats = userStats[user];
		return (stats.totalWorkouts, stats.totalMinutes, stats.totalCalories);
	}

    // Helper function to get the week number
	function getWeek(uint256 timestamp) public pure returns (uint256) {
		return timestamp / 1 weeks;
	}
}