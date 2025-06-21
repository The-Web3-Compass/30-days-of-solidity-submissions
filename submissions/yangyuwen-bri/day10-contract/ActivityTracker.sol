//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

// 设定运动目标，达标触发事件提醒
contract ActivityTracker{
    address public owner;
    mapping(address => userFitnessProfile) public userProfiles;
    uint256 public workoutGoal;
    uint256 public durationGoal; //设定运动时长目标

    constructor(uint256 _workoutGoal, uint256 _durationGoal){
        owner = msg.sender;
        workoutGoal = _workoutGoal;
        durationGoal = _durationGoal;
    }

    struct userFitnessProfile{
        
        uint totalMinutes;
        uint totalWorkouts;
        uint[] workoutTimestamps;

    }

    event GoalReached(address indexed user, string milestone);

    function logWorkout(uint256 _duration) public{

        userFitnessProfile storage user = userProfiles[msg.sender];

        user.totalMinutes += _duration;
        user.totalWorkouts += 1;
        user.workoutTimestamps.push(block.timestamp);

        if(user.totalMinutes >= durationGoal){
            emit GoalReached(msg.sender, "durationGoal reached!");
        }

    }



}