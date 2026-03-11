// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ActivityTracker {

    struct Workout {
        string workoutType;
        uint duration;
        uint calories;
        uint timestamp;
    }

    mapping(address => Workout[]) public workouts;
    mapping(address => uint) public totalMinutes;
    mapping(address => uint) public totalWorkouts;

    event WorkoutLogged(address indexed user, string workoutType, uint duration, uint calories);
    event MilestoneReached(address indexed user, string milestone);

    function logWorkout(string memory _type, uint _duration, uint _calories) public {

        workouts[msg.sender].push(
            Workout(_type, _duration, _calories, block.timestamp)
        );

        totalMinutes[msg.sender] += _duration;
        totalWorkouts[msg.sender] += 1;

        emit WorkoutLogged(msg.sender, _type, _duration, _calories);

        if(totalWorkouts[msg.sender] == 10) {
            emit MilestoneReached(msg.sender, "10 Workouts Completed");
        }

        if(totalMinutes[msg.sender] >= 500) {
            emit MilestoneReached(msg.sender, "500 Minutes Trained");
        }
    }

    function getWorkoutCount(address user) public view returns(uint) {
        return workouts[user].length;
    }

    function getWorkout(address user, uint index) public view returns(string memory, uint, uint, uint) {
        Workout memory w = workouts[user][index];
        return (w.workoutType, w.duration, w.calories, w.timestamp);
    }
}