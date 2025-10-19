// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ActivityTracker {

    struct UserProfile {
        string name;
        uint256 weight;
        bool isRegistered;
    }

    struct WorkoutActivity {
        string activityType;
        uint256 duration;
        uint256 distance;
        uint256 timestamp;
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(address => WorkoutActivity[]) private workoutHistory;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistance;
    mppping(address => uint256) public totalDuration;

    event UserRegistered(
        address indexed userAddress,
        string name,
        uint256 timestamp);
    event UserProfileUpdated(
        address indexed userAddress,
        uint256 weight,
        uint256 timestamp);
    event WorkoutLogged(
        address indexed userAddress,
        string activityType,
        uint256 duration,
        uint256 distance,
        uint256 timestamp);
    // 比如一周内锻炼10次或总共500分钟
    event MilestoneAchieved(
        address indexed userAddress,
        string milestone,
        uint256 timestamp);

    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");

        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        })

        // emit event
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    function updateWeight(uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = userProfiles[msg.sender];

        require(!profile.isRegistered, "User not registered");
        // loss more than 5%
        if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile .weight >= 5){
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }

        profile.weight = _newWeight;

        emit UserProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    function logWorkout(string memory _activityType, uint256 _duration, uint256 _distance) public onlyRegistered {
        WorkoutActivity memory workout = WorkoutActivity({
            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });
        // Add workout to history
        workoutHistory[msg.sender].push(workout);
        // Update total stats
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance;
        totalDuration[msg.sender] += _duration;

        emit WorkoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);

        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "10 Workouts completed", block.timestamp);
        }
        // The first time to reach 100 minutes of workout
        if (totalDuration[msg.sender] >= 100 && totalDuration[msg.sender] - _duration < 100) {
            emit MilestoneAchieved(msg.sender, "100 minutes of workout reached", block.timestamp);
        }
        // The first time to reach 100000 meters(100km) of distance
        if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100km of distance reached", block.timestamp);
        }
    }
}