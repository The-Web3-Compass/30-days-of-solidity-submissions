// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FitTrack {
    struct Workout {
        string workoutType;
        uint256 duration; // in minutes
        uint256 calories;
        uint256 timestamp;
    }

    struct UserStats {
        uint256 totalWorkouts;
        uint256 totalMinutes;
        uint256 totalCalories;
        uint256 lastWeekWorkouts;
        uint256 lastWeekStart;
    }

    mapping(address => Workout[]) private workouts;
    mapping(address => UserStats) public userStats;

    event WorkoutLogged(address indexed user, string workoutType, uint256 duration, uint256 calories);

    event WeeklyGoalReached(address indexed user, uint256 workoutsCount);

    event TotalMinutesMilestone(address indexed user, uint256 totalMinutes);

    function logWorkout(string memory _type, uint256 _duration, uint256 _calories) external {
        require(_duration > 0, "Duration must be greater than 0");

        Workout memory newWorkout = Workout({
            workoutType: _type,
            duration: _duration,
            calories: _calories,
            timestamp: block.timestamp
        });

        workouts[msg.sender].push(newWorkout);
        UserStats storage stats = userStats[msg.sender];

        stats.totalWorkouts += 1;
        stats.totalMinutes += _duration;
        stats.totalCalories += _calories;

        if (block.timestamp > stats.lastWeekStart + 7 days) {
            stats.lastWeekStart = block.timestamp;
            stats.lastWeekWorkouts = 0;
        }

        stats.lastWeekWorkouts += 1;

        emit WorkoutLogged(msg.sender, _type, _duration, _calories);

        if (stats.lastWeekWorkouts == 10) {
            emit WeeklyGoalReached(msg.sender, stats.lastWeekWorkouts);
        }

        if (stats.totalMinutes >= 500 && (stats.totalMinutes - _duration) < 500) {
            emit TotalMinutesMilestone(msg.sender, stats.totalMinutes);
        }
    }

    function getWorkouts(address _user) external view returns (Workout[] memory) {
        return workouts[_user];
    }

    function getUserStats(address _user) external view returns (UserStats memory) {
        return userStats[_user];
    }
}
