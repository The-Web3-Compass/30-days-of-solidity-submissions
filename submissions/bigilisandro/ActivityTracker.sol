// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ActivityTracker {
    // Structs
    struct Workout {
        string workoutType;
        uint256 duration; // in minutes
        uint256 calories;
        uint256 timestamp;
    }

    struct UserProfile {
        string name;
        uint256 weight; // in kg
        bool isRegistered;
    }

    struct UserStats {
        uint256 totalWorkouts;
        uint256 totalMinutes;
        uint256 totalCalories;
        uint256 lastWorkoutTimestamp;
        uint256 weeklyWorkoutCount;
        uint256 weeklyStartTimestamp;
    }

    // State variables
    mapping(address => Workout[]) private userWorkouts;
    mapping(address => UserStats) private userStats;
    mapping(address => mapping(uint256 => bool)) private userMilestones;

    mapping(address => UserProfile) public userProfiles;
    mapping(address => WorkoutActivity[]) private workoutHistory;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistance;

    // Events

    event WeeklyGoalReached(
        address indexed user,
        uint256 workoutCount,
        uint256 weekStartTimestamp
    );

    struct WorkoutActivity {
        string activityType;
        uint256 duration; // in seconds
        uint256 distance; // in meters
        uint256 timestamp;
    }

    event TotalMinutesGoalReached(
        address indexed user,
        uint256 totalMinutes,
        uint256 milestone
    );

    event TotalWorkoutsGoalReached(
        address indexed user,
        uint256 totalWorkouts,
        uint256 milestone
    );

    event UserRegistered(
        address indexed userAddress,
        string name,
        uint256 timestamp
    );
    event ProfileUpdated(
        address indexed userAddress,
        uint256 newWeight,
        uint256 timestamp
    );
    event WorkoutLogged(
        address indexed userAddress,
        string activityType,
        uint256 duration,
        uint256 distance,
        uint256 timestamp
    );
    event MilestoneAchieved(
        address indexed userAddress,
        string milestone,
        uint256 timestamp
    );

    // Constants
    uint256 private constant WEEKLY_WORKOUT_GOAL = 10;
    uint256 private constant MINUTES_MILESTONES = 500;
    uint256 private constant WORKOUTS_MILESTONES = 50;

    // Modifiers
    modifier validWorkout(uint256 _duration, uint256 _calories) {
        require(_duration > 0, "Duration must be greater than 0");
        require(_calories > 0, "Calories must be greater than 0");
        _;
    }

    // Functions
    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    function registerUser(string memory _name, uint256 _weight) public {
        require(
            !userProfiles[msg.sender].isRegistered,
            "User already registered"
        );

        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });

        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    function updateWeight(uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = userProfiles[msg.sender];

        if (
            _newWeight < profile.weight &&
            ((profile.weight - _newWeight) * 100) / profile.weight >= 5
        ) {
            emit MilestoneAchieved(
                msg.sender,
                "Weight Goal Reached",
                block.timestamp
            );
        }

        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    function logWorkout(
        string memory _workoutType,
        uint256 _duration,
        uint256 _calories
    ) external validWorkout(_duration, _calories) {
        // Create new workout
        Workout memory newWorkout = Workout({
            workoutType: _workoutType,
            duration: _duration,
            calories: _calories,
            timestamp: block.timestamp
        });

        // Update user stats
        UserStats storage stats = userStats[msg.sender];
        stats.totalWorkouts++;
        stats.totalMinutes += _duration;
        stats.totalCalories += _calories;
        stats.lastWorkoutTimestamp = block.timestamp;

        // Handle weekly stats
        if (stats.weeklyStartTimestamp == 0) {
            stats.weeklyStartTimestamp = block.timestamp;
        } else if (block.timestamp >= stats.weeklyStartTimestamp + 7 days) {
            stats.weeklyWorkoutCount = 0;
            stats.weeklyStartTimestamp = block.timestamp;
        }
        stats.weeklyWorkoutCount++;

        // Store workout
        userWorkouts[msg.sender].push(newWorkout);

        // Check milestones
        _checkMilestones(stats);

        // Emit workout logged event
        emit WorkoutLogged(
            msg.sender,
            _workoutType,
            _duration,
            _calories,
            block.timestamp
        );
    }

    function getUserWorkoutCount()
        public
        view
        onlyRegistered
        returns (uint256)
    {
        return workoutHistory[msg.sender].length;
    }

    function _checkMilestones(UserStats storage stats) private {
        // Check weekly goal
        if (stats.weeklyWorkoutCount == WEEKLY_WORKOUT_GOAL) {
            emit WeeklyGoalReached(
                msg.sender,
                stats.weeklyWorkoutCount,
                stats.weeklyStartTimestamp
            );
        }

        // Check total minutes milestone
        uint256 minutesMilestone = (stats.totalMinutes / MINUTES_MILESTONES) *
            MINUTES_MILESTONES;
        if (
            minutesMilestone > 0 &&
            !userMilestones[msg.sender][minutesMilestone]
        ) {
            userMilestones[msg.sender][minutesMilestone] = true;
            emit TotalMinutesGoalReached(
                msg.sender,
                stats.totalMinutes,
                minutesMilestone
            );
        }

        // Check total workouts milestone
        uint256 workoutsMilestone = (stats.totalWorkouts /
            WORKOUTS_MILESTONES) * WORKOUTS_MILESTONES;
        if (
            workoutsMilestone > 0 &&
            !userMilestones[msg.sender][workoutsMilestone]
        ) {
            userMilestones[msg.sender][workoutsMilestone] = true;
            emit TotalWorkoutsGoalReached(
                msg.sender,
                stats.totalWorkouts,
                workoutsMilestone
            );
        }
    }

    // View functions
    function getUserStats(
        address _user
    )
        external
        view
        returns (
            uint256 totalWorkouts,
            uint256 totalMinutes,
            uint256 totalCalories,
            uint256 lastWorkoutTimestamp,
            uint256 weeklyWorkoutCount,
            uint256 weeklyStartTimestamp
        )
    {
        UserStats storage stats = userStats[_user];
        return (
            stats.totalWorkouts,
            stats.totalMinutes,
            stats.totalCalories,
            stats.lastWorkoutTimestamp,
            stats.weeklyWorkoutCount,
            stats.weeklyStartTimestamp
        );
    }

    function getUserWorkouts(
        address _user
    ) external view returns (Workout[] memory) {
        return userWorkouts[_user];
    }

    function hasReachedMilestone(
        address _user,
        uint256 _milestone
    ) external view returns (bool) {
        return userMilestones[_user][_milestone];
    }
}
