// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ActivityTracker {
    // We're building a fitness tracker

    struct UserProfile {
        string name;
        uint256 weight; // in kg
        bool isRegistered;
    }

    struct WorkoutActivity {
        string activityType; // "Running", "Cycling", "Swimming", etc
        uint256 duration; // in seconds
        uint256 distance; // in meters
        uint256 timestamp; // when the workout was logged
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(address => WorkoutActivity[]) private workoutHistory;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistance;

    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(address indexed userAddress, string activityType, uint256 duration, uint256 distance, uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);

    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "You must register first.");
        _;
    }

    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered.");
        require(_weight > 0, "Weight must be greater than zero.");

        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });

        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    function updateWeight(uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = userProfiles[msg.sender];

        // Check if they lost 5% or more of their bodyweight
        if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5) {
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached!", block.timestamp);
        }

        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    function logWorkout(string memory _activityType, uint256 _duration, uint256 _distance) public onlyRegistered {
        require(_duration > 0, "Duration must be greater than zero.");
        require(_distance >= 0, "Distance cannot be negative.");

        // Create the workout record
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });

        // Store it and update counters
        workoutHistory[msg.sender].push(newWorkout);
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance;

        // Broadcast the workout
        emit WorkoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);

        // Check for workout count milestones
        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed!", block.timestamp);
        } else if (totalWorkouts[msg.sender] == 50) {
            emit MilestoneAchieved(msg.sender, "50 Workouts Completed!", block.timestamp);
        } else if (totalWorkouts[msg.sender] == 100) {
            emit MilestoneAchieved(msg.sender, "100 Workouts Completed!", block.timestamp);
        }

        // Check for distace milestone (100km = 100,000 meters)
        if (totalDistance[msg.sender] >=100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100k Total Distance", block.timestamp);
        }
    }
}