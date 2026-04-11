// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ActivityTracker {

    struct Activity {
        uint steps;
        uint calories;
        string activityType;
        uint timestamp;
    }

    mapping(address => Activity[]) public userActivities;
    mapping(address => uint) public stepGoal;
    mapping(address => uint) public totalSteps;

    event GoalSet(address indexed user, uint goal);
    event GoalAchieved(address indexed user, uint totalSteps);

    event ActivityLogged(
        address indexed user,
        uint steps,
        uint calories,
        string activityType,
        uint timestamp
    );

    function logActivity(uint _steps, uint _calories, string memory _type) public {
        Activity memory newActivity = Activity({
            steps: _steps,
            calories: _calories,
            activityType: _type,
            timestamp: block.timestamp
        });

        userActivities[msg.sender].push(newActivity);

        totalSteps[msg.sender] += _steps;

        emit ActivityLogged(msg.sender, _steps, _calories, _type, block.timestamp);

        if (
            stepGoal[msg.sender] != 0 &&
            totalSteps[msg.sender] >= stepGoal[msg.sender]
        ) {
            emit GoalAchieved(msg.sender, totalSteps[msg.sender]);
        }
    }

    function getMyActivities() public view returns (Activity[] memory) {
        return userActivities[msg.sender];
    }

    function setGoal(uint _goal) public {
        stepGoal[msg.sender] = _goal;

        emit GoalSet(msg.sender, _goal);

        if (
            _goal != 0 &&
            totalSteps[msg.sender] >= _goal
        ) {
            emit GoalAchieved(msg.sender, totalSteps[msg.sender]);
        }
    }
}