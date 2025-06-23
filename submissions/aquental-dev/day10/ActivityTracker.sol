// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ActivityTracker contract to log user workouts and track fitness milestones
contract ActivityTracker {
    // Struct to store workout session details
    struct Workout {
        string workoutType; // Type of workout (e.g., running, cycling)
        uint256 duration; // Duration in minutes
        uint256 calories; // Calories burned
        uint256 timestamp; // Timestamp of the workout
    }

    // Struct to track weekly workout stats
    struct WeeklyStats {
        uint256 workoutCount; // Number of workouts in the week
        uint256 totalMinutes; // Total minutes worked out in the week
        uint256 weekStart; // Timestamp of the week's start
    }

    // Struct to track overall user stats
    struct UserStats {
        uint256 totalWorkouts; // Total workouts logged
        uint256 totalMinutes; // Total minutes across all workouts
    }

    // Mapping from user address to their workout history
    mapping(address => Workout[]) private userWorkouts;

    // Mapping from user address to their weekly stats
    mapping(address => WeeklyStats) private userWeeklyStats;

    // Mapping from user address to their overall stats
    mapping(address => UserStats) private userOverallStats;

    // Events for logging workouts and milestones
    event WorkoutLogged(
        address indexed user,
        string workoutType,
        uint256 duration,
        uint256 calories,
        uint256 timestamp
    );

    event WeeklyWorkoutGoalReached(
        address indexed user,
        uint256 workoutCount,
        uint256 weekStart
    );

    event WeeklyMinutesGoalReached(
        address indexed user,
        uint256 totalMinutes,
        uint256 weekStart
    );

    event TotalMinutesGoalReached(address indexed user, uint256 totalMinutes);

    // Constant for seconds in a week (7 days)
    uint256 private constant WEEK_SECONDS = 7 * 24 * 60 * 60;

    // Constant for weekly workout goal (10 workouts)
    uint256 private constant WEEKLY_WORKOUT_GOAL = 10;

    // Constant for weekly minutes goal (500 minutes)
    uint256 private constant WEEKLY_MINUTES_GOAL = 500;

    // Constant for total minutes goal (500 minutes)
    uint256 private constant TOTAL_MINUTES_GOAL = 500;

    // Logs a workout session and updates user stats
    function logWorkout(
        string calldata workoutType,
        uint256 duration,
        uint256 calories
    ) external {
        require(bytes(workoutType).length > 0, "Workout type cannot be empty");
        require(duration > 0, "Duration must be greater than zero");
        require(calories > 0, "Calories must be greater than zero");

        Workout memory newWorkout = Workout({
            workoutType: workoutType,
            duration: duration,
            calories: calories,
            timestamp: block.timestamp
        });

        address user = msg.sender;
        userWorkouts[user].push(newWorkout);

        // Update overall stats
        userOverallStats[user].totalWorkouts += 1;
        userOverallStats[user].totalMinutes += duration;

        // Update weekly stats
        updateWeeklyStats(user, duration);

        // Emit workout logged event
        emit WorkoutLogged(
            user,
            workoutType,
            duration,
            calories,
            block.timestamp
        );

        // Check for total minutes goal
        if (
            userOverallStats[user].totalMinutes >= TOTAL_MINUTES_GOAL &&
            userOverallStats[user].totalMinutes - duration < TOTAL_MINUTES_GOAL
        ) {
            emit TotalMinutesGoalReached(
                user,
                userOverallStats[user].totalMinutes
            );
        }
    }

    // Updates weekly stats and checks for weekly goals
    function updateWeeklyStats(address user, uint256 duration) private {
        uint256 currentWeekStart = block.timestamp -
            (block.timestamp % WEEK_SECONDS);

        // Reset weekly stats if new week
        if (userWeeklyStats[user].weekStart != currentWeekStart) {
            userWeeklyStats[user] = WeeklyStats({
                workoutCount: 0,
                totalMinutes: 0,
                weekStart: currentWeekStart
            });
        }

        // Update weekly stats
        userWeeklyStats[user].workoutCount += 1;
        userWeeklyStats[user].totalMinutes += duration;

        // Check weekly workout goal
        if (userWeeklyStats[user].workoutCount == WEEKLY_WORKOUT_GOAL) {
            emit WeeklyWorkoutGoalReached(
                user,
                userWeeklyStats[user].workoutCount,
                userWeeklyStats[user].weekStart
            );
        }

        // Check weekly minutes goal
        if (
            userWeeklyStats[user].totalMinutes >= WEEKLY_MINUTES_GOAL &&
            userWeeklyStats[user].totalMinutes - duration < WEEKLY_MINUTES_GOAL
        ) {
            emit WeeklyMinutesGoalReached(
                user,
                userWeeklyStats[user].totalMinutes,
                userWeeklyStats[user].weekStart
            );
        }
    }

    // Retrieves a user's workout history
    function getWorkoutHistory(
        address user
    ) external view returns (Workout[] memory) {
        return userWorkouts[user];
    }

    // Retrieves a user's weekly stats
    function getWeeklyStats(
        address user
    ) external view returns (WeeklyStats memory) {
        return userWeeklyStats[user];
    }

    // Retrieves a user's overall stats
    function getOverallStats(
        address user
    ) external view returns (UserStats memory) {
        return userOverallStats[user];
    }
}
