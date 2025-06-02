// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ActivityTracker {
    
    struct Activity {
        string activityType;
        uint256 duration;
        uint256 timestamp;
    }

    struct Goal {
        uint256 sessionTarget;
        uint256 timeTarget;
    }

    mapping(address => Activity[]) public userActivities;
    mapping(address => Goal) public userGoals;
    mapping(address => uint256) public totalMinutes;
    mapping(address => uint256) public totalSessions;

    mapping(address => bool) public hasReachedSessionGoal;
    mapping(address => bool) public hasReachedTimeGoal;

    event ActivityLogged(address indexed user, string activityType, uint256 duration);
    event SessionGoalReached(address indexed user);
    event TimeGoalReached(address indexed user);

    function logActivity(string memory activityType, uint256 duration) public {
        Activity memory userActivity = Activity({
            activityType: activityType,
            duration: duration,
            timestamp: block.timestamp
        });

        userActivities[msg.sender].push(userActivity);
        totalMinutes[msg.sender] += duration;
        totalSessions[msg.sender] += 1;

        emit ActivityLogged(msg.sender, activityType, duration);

        // Check each goal individually
        (bool sessionGoalReached, bool timeGoalReached) = checkGoalStatus();

        if (sessionGoalReached && !hasReachedSessionGoal[msg.sender]) {
            hasReachedSessionGoal[msg.sender] = true;
            emit SessionGoalReached(msg.sender);
        }

        if (timeGoalReached && !hasReachedTimeGoal[msg.sender]) {
            hasReachedTimeGoal[msg.sender] = true;
            emit TimeGoalReached(msg.sender);
        }
    }

    function setGoal(uint256 sessionTarget, uint256 timeTarget) public {
        userGoals[msg.sender] = Goal(sessionTarget, timeTarget);
    }

    function checkGoalStatus() public view returns (bool sessionGoalReached, bool timeGoalReached) {
        Goal memory userCurrentGoal = userGoals[msg.sender];
        sessionGoalReached = totalSessions[msg.sender] >= userCurrentGoal.sessionTarget;
        timeGoalReached = totalMinutes[msg.sender] >= userCurrentGoal.timeTarget;
    }
    
    function getSummary() public view returns (
        uint256 totalSessionCount,
        uint256 totalTimeSpent,
        uint256 sessionTarget,
        uint256 timeTarget,
        bool hasReachedSession,
        bool hasReachedTime
    ){

        Goal memory userCurrentGoal = userGoals[msg.sender];
        totalSessionCount = totalSessions[msg.sender];
        totalTimeSpent = totalMinutes[msg.sender];
        sessionTarget = userCurrentGoal.sessionTarget;
        timeTarget = userCurrentGoal.timeTarget;    
        hasReachedSession = hasReachedSessionGoal[msg.sender];
        hasReachedTime = hasReachedTimeGoal[msg.sender];

        return (totalSessionCount , totalTimeSpent, sessionTarget, timeTarget, hasReachedSession, hasReachedTime);
        
    }

    function getActivities() public view returns (Activity[] memory) {
        return userActivities[msg.sender];
    }
}
