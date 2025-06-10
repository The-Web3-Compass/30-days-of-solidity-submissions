// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ActivityTracker {
    struct Workout {
        string workoutType;
        uint256 durationMinutes;
        uint256 caloriesBurned;
        uint256 timestamp;
    }

    mapping(address => Workout[]) public userWorkouts;
    mapping(address => uint256) public totalMinutes;

    // Events
    event WorkoutLogged(
        address indexed user,
        string workoutType,
        uint256 duration,
        uint256 calories
    );
    event MilestoneReached(address indexed user, string milestone);
    event GoalReached(address user, string goal);

    // Log a workout
    function logWorkout(
        string memory _type,
        uint256 _duration,
        uint256 _calories
    ) external {
        Workout memory workout = Workout({
            workoutType: _type,
            durationMinutes: _duration,
            caloriesBurned: _calories,
            timestamp: block.timestamp
        });

        userWorkouts[msg.sender].push(workout);
        totalMinutes[msg.sender] += _duration;

        emit WorkoutLogged(msg.sender, _type, _duration, _calories);

        if (totalMinutes[msg.sender] >= 500) {
            emit GoalReached(msg.sender, "500 minutes achieved!");
        }
    }

    // View total workouts
    function getWorkoutCount(address _user) external view returns (uint256) {
        return userWorkouts[_user].length;
    }

    // View total minutes
    function getTotalMinutes(address _user) external view returns (uint256) {
        return totalMinutes[_user];
    }

    // Optional: get all workouts
    function getWorkouts(
        address _user
    ) external view returns (Workout[] memory) {
        return userWorkouts[_user];
    }
}
