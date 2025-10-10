// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ActivityTracker {
    struct Workout {
        string workoutType;
        uint duration; // in minutes
        uint calories;
    }

    mapping(address => Workout[]) public userWorkouts;
    mapping(address => uint) public totalMinutes;
    mapping(address => uint) public totalWorkouts;

    // 🏋️ Events
    event WorkoutLogged(address indexed user, string workoutType, uint duration, uint calories);
    event GoalReached(address indexed user, string goalType, uint value);

    // Log a workout
    function logWorkout(string memory _type, uint _duration, uint _calories) public {
        userWorkouts[msg.sender].push(Workout(_type, _duration, _calories));
        totalWorkouts[msg.sender] += 1;
        totalMinutes[msg.sender] += _duration;

        emit WorkoutLogged(msg.sender, _type, _duration, _calories);

        // 🎯 Trigger goals
        if (totalWorkouts[msg.sender] == 10) {
            emit GoalReached(msg.sender, "10 Workouts Milestone", totalWorkouts[msg.sender]);
        }
        if (totalMinutes[msg.sender] >= 500) {
            emit GoalReached(msg.sender, "500 Minutes Milestone", totalMinutes[msg.sender]);
        }
    }

    function getTotalWorkouts(address user) public view returns (uint) {
        return totalWorkouts[user];
    }

    function getTotalMinutes(address user) public view returns (uint) {
        return totalMinutes[user];
    }
}
