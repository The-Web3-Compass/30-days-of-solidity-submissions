// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract AcivityTracker {
    address public owner;
    struct ActivitySession {
        string activityType;
        uint duration;
        uint calories;
        uint timestamp;
    }
    mapping(address => ActivitySession[]) userProfile;
    mapping(address => bool) registeredUsers;
    address[] public users;

    event GoalCompleted(address user, uint workouts, uint totalTime);

    constructor() {
        owner = msg.sender;
    }

    function addWorkout(
        string memory _activityType,
        uint _duration,
        uint _calories
    ) public {
        require(_duration > 0, "thoda der to kar");
        require(_calories > 0, "thoda calorie to ghata le");

        ActivitySession memory activitySession = ActivitySession(
            _activityType,
            _duration,
            _calories,
            block.timestamp
        );
        userProfile[msg.sender].push(activitySession);

        (
            bool goalAchieved,
            uint totalWorkouts,
            uint totalMinutes
        ) = isGoalReached();
        if (goalAchieved) {
            emit GoalCompleted(msg.sender, totalWorkouts, totalMinutes);
        }

        if (!registeredUsers[msg.sender]) {
            users.push(msg.sender);
            registeredUsers[msg.sender] = true;
        }
    }

    function isGoalReached() public view returns (bool, uint, uint) {
        ActivitySession[] memory activitySessions = userProfile[msg.sender];

        uint workoutsInWeek = 0;
        uint totalTimeInWeek = 0;
        uint oneWeekAgo = block.timestamp - 7 days;
        bool goalReached = false;

        for (uint i = 0; i < activitySessions.length; i++) {
            if (activitySessions[i].timestamp >= oneWeekAgo) {
                totalTimeInWeek += activitySessions[i].duration;
                workoutsInWeek++;
            }
        }

        if (totalTimeInWeek >= 500 || workoutsInWeek >= 10) {
            goalReached = true;
        }

        return (goalReached, workoutsInWeek, totalTimeInWeek);
    }
}
