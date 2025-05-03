// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Activity Tracker - Logs workouts and emits milestone events
contract ActivityTracker {
    struct Workout {
        string activityType;
        uint duration; // in minutes
        uint calories;
        uint timestamp;
    }

    mapping(address => Workout[]) public userWorkouts;
    mapping(address => uint) public totalMinutes;
    mapping(address => uint) public totalWorkouts;

    event WorkoutLogged(address indexed user, string activityType, uint duration);
    event MilestoneAchieved(address indexed user, string milestone);

    /// @notice Logs a workout session for the caller
    /// @param activityType Type of workout (e.g. "Running", "Yoga")
    /// @param duration Duration in minutes
    /// @param calories Calories burned
    function logWorkout(string calldata activityType, uint duration, uint calories) external {
        require(duration > 0, "Duration must be > 0");

        Workout memory workout = Workout({
            activityType: activityType,
            duration: duration,
            calories: calories,
            timestamp: block.timestamp
        });

        userWorkouts[msg.sender].push(workout);
        totalMinutes[msg.sender] += duration;
        totalWorkouts[msg.sender] += 1;

        emit WorkoutLogged(msg.sender, activityType, duration);

        // Emit milestone events
        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "Completed 10 Workouts!");
        }

        if (totalMinutes[msg.sender] >= 500 && totalMinutes[msg.sender] - duration < 500) {
            emit MilestoneAchieved(msg.sender, "Achieved 500 Total Minutes!");
        }
    }

    /// @notice Returns all workouts of a user
    /// @param user Address of the user
    function getUserWorkouts(address user) external view returns (Workout[] memory) {
        return userWorkouts[user];
    }
}
