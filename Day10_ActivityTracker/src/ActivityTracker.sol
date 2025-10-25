// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ActivityTracker
 * @dev Logs user workouts, tracks milestones, and emits events when goals are achieved.
 */
contract ActivityTracker {
    struct Workout {
        string workoutType;
        uint256 duration; // in minutes
        uint256 calories;
        uint256 timestamp;
    }

    mapping(address => Workout[]) private userWorkouts;
    mapping(address => uint256) public totalDuration;
    mapping(address => uint256) public totalWorkouts;

    event WorkoutLogged(address indexed user, string workoutType, uint256 duration, uint256 calories);
    event GoalReached(address indexed user, string goalType, uint256 value);

    function logWorkout(string calldata _type, uint256 _duration, uint256 _calories) external {
        require(_duration > 0, "Duration must be positive");

        Workout memory workout = Workout({
            workoutType: _type,
            duration: _duration,
            calories: _calories,
            timestamp: block.timestamp
        });

        userWorkouts[msg.sender].push(workout);
        totalDuration[msg.sender] += _duration;
        totalWorkouts[msg.sender]++;

        emit WorkoutLogged(msg.sender, _type, _duration, _calories);

        // Emit achievement events
        if (totalWorkouts[msg.sender] == 10) {
            emit GoalReached(msg.sender, "Workout Milestone", totalWorkouts[msg.sender]);
        }

        if (totalDuration[msg.sender] >= 500) {
            emit GoalReached(msg.sender, "Duration Milestone", totalDuration[msg.sender]);
        }
    }

    function getUserWorkouts(address _user) external view returns (Workout[] memory) {
        return userWorkouts[_user];
    }
}
