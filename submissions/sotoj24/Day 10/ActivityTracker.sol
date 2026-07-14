// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ActivityTracker {
    struct Workout {
        string workoutType;
        uint256 durationMinutes;
        uint256 caloriesBurned;
        uint256 timestamp;
    }

    mapping(address => Workout[]) public workoutLogs;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalMinutes;

    event WorkoutLogged(
        address indexed user,
        string workoutType,
        uint256 durationMinutes,
        uint256 caloriesBurned
    );

    event MilestoneReached(address indexed user, string milestoneType, uint256 value);

    function logWorkout(string calldata _type, uint256 _minutes, uint256 _calories) external {
        require(_minutes > 0, "Workout must be at least 1 minute");

        workoutLogs[msg.sender].push(Workout({
            workoutType: _type,
            durationMinutes: _minutes,
            caloriesBurned: _calories,
            timestamp: block.timestamp
        }));

        totalWorkouts[msg.sender] += 1;
        totalMinutes[msg.sender] += _minutes;

        emit WorkoutLogged(msg.sender, _type, _minutes, _calories);

        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneReached(msg.sender, "10 Workouts", 10);
        }

        if (totalMinutes[msg.sender] >= 500 && totalMinutes[msg.sender] - _minutes < 500) {
            emit MilestoneReached(msg.sender, "500 Minutes", totalMinutes[msg.sender]);
        }
    }

    function getMyWorkouts() external view returns (Workout[] memory) {
        return workoutLogs[msg.sender];
    }
}
