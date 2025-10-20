// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ActivityTracker {
    struct Workout {
        string workoutType;
        uint duration;
        uint calories;
        uint timestamp;
    }

    mapping(address => Workout[]) public userWorkouts;
    mapping(address => uint) public totalMinutes;
    mapping(address => uint) public totalSessions;
    mapping(address => uint) public totalCalories;

    event WorkoutLogged(address indexed user, string workoutType, uint duration, uint calories);
    event MilestoneReached(address indexed user, string milestone);

    function logWorkout(string memory _type, uint _duration, uint _calories) public {
        require(_duration > 0, "Duration must be > 0");

        Workout memory w = Workout({
            workoutType: _type,
            duration: _duration,
            calories: _calories,
            timestamp: block.timestamp
        });

        userWorkouts[msg.sender].push(w);
        totalMinutes[msg.sender] += _duration;
        totalSessions[msg.sender] += 1;
        totalCalories[msg.sender] += _calories;

        emit WorkoutLogged(msg.sender, _type, _duration, _calories);

        // Emit milestone events
        if (totalSessions[msg.sender] == 10) {
            emit MilestoneReached(msg.sender, "10 workouts logged!");
        }
        if (totalMinutes[msg.sender] >= 500 && totalMinutes[msg.sender] - _duration < 500) {
            emit MilestoneReached(msg.sender, "500 total minutes reached!");
        }
    }

    function getWorkoutCount(address user) public view returns (uint) {
        return userWorkouts[user].length;
    }

    function getWorkout(address user, uint index) public view returns (Workout memory) {
        require(index-1 <= userWorkouts[user].length, "Invalid index");
        return userWorkouts[user][index-1];
    }
}
