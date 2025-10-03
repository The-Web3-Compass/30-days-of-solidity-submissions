// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ActivityTracker {
    struct Workout {
        string workoutType;
        uint256 duration;
        uint256 calories;
        uint256 timestamp;
    }

    mapping (address => Workout[]) public workouts;
    mapping (address => uint256) public weeklyWorkoutCount;
    mapping (address => uint256) public totalMinutes;
    mapping (address => uint256) public fitnessGoal;

    event WorkoutLogged(
        address indexed user, 
        string workoutType, 
        uint256 duration, 
        uint256 calories, 
        uint256 timestamp
    );

    event GoalReached(
        address indexed user, 
        string milestone, 
        uint256 duration
    );

    function setGoal(uint256 _goal) public {
        require (_goal > 0, "Invalid entry");
        fitnessGoal[msg.sender] = _goal;
    }
 
    function logWorkout(string memory _workoutType, uint _duration, uint _calories) public {
        Workout memory newWorkout;
        newWorkout.workoutType = _workoutType;
        newWorkout.duration = _duration;
        newWorkout.calories = _calories;
        newWorkout.timestamp = block.timestamp;
        
        workouts[msg.sender].push(newWorkout);
        weeklyWorkoutCount[msg.sender] += 1;
        totalMinutes[msg.sender] += _duration;

        emit WorkoutLogged(msg.sender, _workoutType, _duration, _calories, newWorkout.timestamp);

        if (weeklyWorkoutCount[msg.sender] == 10){
            emit GoalReached(msg.sender, "10 Workout sessions!", _duration);
        }

        if (totalMinutes[msg.sender] >= fitnessGoal[msg.sender] && fitnessGoal[msg.sender] > 0) {
            emit GoalReached(msg.sender, "Total duration goal", totalMinutes[msg.sender]);
        }

    }

    function getWorkoutHistory() public view returns (uint256){
        return workouts[msg.sender].length;
    }

    function getStats() public view returns (uint256 totalWorkoutMinutes, uint256 totalWorkouts){
        return (totalMinutes[msg.sender], weeklyWorkoutCount[msg.sender]);
    }

    function resetWeeklyCounter() public {
        weeklyWorkoutCount[msg.sender] = 0;
    }
}