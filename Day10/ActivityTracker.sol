// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ActivityTracker {
    struct Workout {
        string activityType;
        uint256 duration;
        uint256 calories;
        uint256 timestamp;
    }

    mapping(address => Workout[]) private workoutHistory;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDuration;

    event WorkoutLogged(
        address indexed user,
        string activityType,
        uint256 duration,
        uint256 calories,
        uint256 timestamp
    );

    event GoalAchieved(address indexed user, string goal, uint256 timestamp);

    function logWorkout(
        string memory _activityType,
        uint256 _duration,
        uint256 _calories
    ) public {
        require(_duration > 0, "Duration must be positive");

        Workout memory newWorkout = Workout({
            activityType: _activityType,
            duration: _duration,
            calories: _calories,
            timestamp: block.timestamp
        });

        workoutHistory[msg.sender].push(newWorkout);
        totalWorkouts[msg.sender]++;
        totalDuration[msg.sender] += _duration;

        emit WorkoutLogged(msg.sender, _activityType, _duration, _calories, block.timestamp);

        if (totalWorkouts[msg.sender] == 10) {
            emit GoalAchieved(msg.sender, "10 Workouts Completed!", block.timestamp);
        }

        if (totalDuration[msg.sender] >= 500 && totalDuration[msg.sender] - _duration < 500) {
            emit GoalAchieved(msg.sender, "500 Total Minutes!", block.timestamp);
        }
    }

    function getWorkouts(address user) public view returns (Workout[] memory) {
        return workoutHistory[user];
    }
}
