// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ActivityTracker {
    struct Workout {
        string workoutType;
        uint256 duration; // in minutes
        uint256 calories;
        uint256 timestamp;
    }

    // Mapping of user => all workouts
    mapping(address => Workout[]) public userWorkouts;

    // Events
    event WorkoutLogged(address indexed user, string workoutType, uint256 duration, uint256 calories);
    event MilestoneReached(address indexed user, string milestone);

    // Log a new workout
    function logWorkout(string calldata _type, uint256 _duration, uint256 _calories) external {
        require(_duration > 0, "Duration must be greater than zero");
        require(_calories > 0, "Calories must be greater than zero");

        // Store workout details
        userWorkouts[msg.sender].push(Workout({
            workoutType: _type,
            duration: _duration,
            calories: _calories,
            timestamp: block.timestamp
        }));

        emit WorkoutLogged(msg.sender, _type, _duration, _calories);

        // Check and emit milestones
        _checkMilestones(msg.sender);
    }

    // Check if the user has reached any fitness milestones
    function _checkMilestones(address _user) internal {
        uint256 totalWorkouts = userWorkouts[_user].length;
        uint256 totalMinutes = 0;

        // Calculate total minutes
        for (uint256 i = 0; i < totalWorkouts; i++) {
            totalMinutes += userWorkouts[_user][i].duration;
        }

        if (totalWorkouts == 10) {
            emit MilestoneReached(_user, "Completed 10 workouts!");
        }

        if (totalMinutes >= 500) {
            emit MilestoneReached(_user, "Reached 500 total workout minutes!");
        }
    }

    // Get total workouts for a user
    function getWorkoutCount(address _user) external view returns (uint256) {
        return userWorkouts[_user].length;
    }

    // Get all workouts for a user
    function getWorkouts(address _user) external view returns (Workout[] memory) {
        return userWorkouts[_user];
    }
}
