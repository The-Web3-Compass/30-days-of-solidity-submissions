// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// A contract to help users track fitness activities like workouts and weight changes
contract SimpleFitnessTracker {
    address public owner;

    // Structure to hold user profile information
    struct UserProfile {
        string name;
        uint256 weight; // User's current weight in kg or any consistent unit
        bool isRegistered; // Flag to ensure the user has registered
    }

    // Structure to represent a workout activity
    struct WorkoutActivity {
        string activityType; // e.g., "Run", "Walk", "Cycling"
        uint256 duration;    // in seconds
        uint256 distance;    // in meters
        uint256 timestamp;   // time the workout was logged
    }

    // Mapping from user address to their profile
    mapping(address => UserProfile) public userProfiles;

    // Mapping to keep track of all workouts per user
    mapping(address => WorkoutActivity[]) private workoutHistory;

    // Mapping to track total workouts per user
    mapping(address => uint256) public totalWorkouts;

    // Mapping to track total distance covered by each user
    mapping(address => uint256) public totalDistance;

    // Event emitted when a user registers
    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);

    // Event emitted when a user's weight is updated
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);

    // Event emitted when a workout is logged
    event WorkoutLogged(
        address indexed userAddress,
        string activityType,
        uint256 duration,
        uint256 distance,
        uint256 timestamp
    );

    // Event emitted when a user achieves a workout milestone
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);

    // Contract constructor sets the deployer as the owner
    constructor() {
        owner = msg.sender;
    }

    // Modifier to allow only registered users to access certain functions
    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    // Allows a user to register with their name and weight
    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");

        // Store user profile
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });

        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    // Allows registered users to update their weight
    function updateWeight(uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = userProfiles[msg.sender];

        // If weight decreased by 5% or more, emit milestone event
        if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5) {
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }

        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    // Log a new workout activity for the sender
    function logWorkout(
        string memory _activityType,
        uint256 _duration,
        uint256 _distance
    ) public onlyRegistered {
        // Create a new workout entry
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });

        // Store workout for user
        workoutHistory[msg.sender].push(newWorkout);

        // Update summary statistics
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance;

        emit WorkoutLogged(
            msg.sender,
            _activityType,
            _duration,
            _distance,
            block.timestamp
        );

        // Milestone: 10 workouts
        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        }
        // Milestone: 50 workouts
        else if (totalWorkouts[msg.sender] == 50) {
            emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }

        // Milestone: crossing 100km distance for the first time
        if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        }
    }

    // Returns the number of workouts the sender has logged
    function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
        return workoutHistory[msg.sender].length;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// A contract to help users track fitness activities like workouts and weight changes
contract SimpleFitnessTracker {
    address public owner;

    // Structure to hold user profile information
    struct UserProfile {
        string name;
        uint256 weight; // User's current weight in kg or any consistent unit
        bool isRegistered; // Flag to ensure the user has registered
    }

    // Structure to represent a workout activity
    struct WorkoutActivity {
        string activityType; // e.g., "Run", "Walk", "Cycling"
        uint256 duration;    // in seconds
        uint256 distance;    // in meters
        uint256 timestamp;   // time the workout was logged
    }

    // Mapping from user address to their profile
    mapping(address => UserProfile) public userProfiles;

    // Mapping to keep track of all workouts per user
    mapping(address => WorkoutActivity[]) private workoutHistory;

    // Mapping to track total workouts per user
    mapping(address => uint256) public totalWorkouts;

    // Mapping to track total distance covered by each user
    mapping(address => uint256) public totalDistance;

    // Event emitted when a user registers
    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);

    // Event emitted when a user's weight is updated
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);

    // Event emitted when a workout is logged
    event WorkoutLogged(
        address indexed userAddress,
        string activityType,
        uint256 duration,
        uint256 distance,
        uint256 timestamp
    );

    // Event emitted when a user achieves a workout milestone
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);

    // Contract constructor sets the deployer as the owner
    constructor() {
        owner = msg.sender;
    }

    // Modifier to allow only registered users to access certain functions
    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    // Allows a user to register with their name and weight
    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");

        // Store user profile
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });

        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    // Allows registered users to update their weight
    function updateWeight(uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = userProfiles[msg.sender];

        // If weight decreased by 5% or more, emit milestone event
        if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5) {
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }

        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    // Log a new workout activity for the sender
    function logWorkout(
        string memory _activityType,
        uint256 _duration,
        uint256 _distance
    ) public onlyRegistered {
        // Create a new workout entry
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });

        // Store workout for user
        workoutHistory[msg.sender].push(newWorkout);

        // Update summary statistics
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance;

        emit WorkoutLogged(
            msg.sender,
            _activityType,
            _duration,
            _distance,
            block.timestamp
        );

        // Milestone: 10 workouts
        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        }
        // Milestone: 50 workouts
        else if (totalWorkouts[msg.sender] == 50) {
            emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }

        // Milestone: crossing 100km distance for the first time
        if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        }
    }

    // Returns the number of workouts the sender has logged
    function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
        return workoutHistory[msg.sender].length;
    }
}