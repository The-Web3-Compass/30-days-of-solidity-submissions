// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ActivityTracker {
    struct Workout {
        uint256 timestamp;
        string activityType;
        uint256 duration;
        uint256 calories;
    }
    
    mapping(address => Workout[]) public userWorkouts;
    mapping(address => mapping(uint256 => uint256)) public weeklyWorkouts;
    mapping(address => mapping(uint256 => uint256)) public weeklyDuration;
    mapping(address => uint256) public totalDuration;
    mapping(address => uint256) public totalCalories;
    mapping(address => mapping(uint256 => bool)) public weeklyGoalAchieved;
    mapping(address => bool) public totalDurationGoalAchieved;
    
    event WorkoutLogged(
        address indexed user,
        string activityType,
        uint256 duration,
        uint256 calories,
        uint256 timestamp
    );
    
    event WeeklyGoalReached(
        address indexed user,
        uint256 week,
        uint256 workoutCount
    );
    
    event TotalDurationGoalReached(
        address indexed user,
        uint256 totalDuration
    );
    
    function logWorkout(
        string memory activityType,
        uint256 duration,  // 分钟
        uint256 calories
    ) external {
        require(duration > 0, "Duration must be positive");
        require(calories > 0, "Calories must be positive");
        require(bytes(activityType).length > 0, "Activity type required");
        
        uint256 timestamp = block.timestamp;
        
        Workout memory newWorkout = Workout({
            timestamp: timestamp,
            activityType: activityType,
            duration: duration,
            calories: calories
        });
        
        userWorkouts[msg.sender].push(newWorkout);
        
        totalDuration[msg.sender] += duration;
        totalCalories[msg.sender] += calories;
        
        uint256 week = timestamp / 1 weeks;
        
        weeklyWorkouts[msg.sender][week] += 1;
        weeklyDuration[msg.sender][week] += duration;
        
        if (weeklyWorkouts[msg.sender][week] >= 10 && 
            !weeklyGoalAchieved[msg.sender][week]) {
            
            weeklyGoalAchieved[msg.sender][week] = true;
            emit WeeklyGoalReached(
                msg.sender, 
                week, 
                weeklyWorkouts[msg.sender][week]
            );
        }
        
        if (totalDuration[msg.sender] >= 500 && 
            !totalDurationGoalAchieved[msg.sender]) {
            
            totalDurationGoalAchieved[msg.sender] = true;
            emit TotalDurationGoalReached(
                msg.sender, 
                totalDuration[msg.sender]
            );
        }
        
        emit WorkoutLogged(
            msg.sender, 
            activityType, 
            duration, 
            calories, 
            timestamp
        );
    }
    
    function getWorkoutCount(address user) external view returns (uint256) {
        return userWorkouts[user].length;
    }
    
    function getWorkout(address user, uint256 index) external view returns (
        uint256 timestamp,
        string memory activityType,
        uint256 duration,
        uint256 calories
    ) {
        require(index < userWorkouts[user].length, "Invalid index");
        Workout memory workout = userWorkouts[user][index];
        return (
            workout.timestamp,
            workout.activityType,
            workout.duration,
            workout.calories
        );
    }
    
    function getCurrentWeekWorkouts(address user) external view returns (uint256) {
        uint256 currentWeek = block.timestamp / 1 weeks;
        return weeklyWorkouts[user][currentWeek];
    }
    
    function getCurrentWeekDuration(address user) external view returns (uint256) {
        uint256 currentWeek = block.timestamp / 1 weeks;
        return weeklyDuration[user][currentWeek];
    }
}
