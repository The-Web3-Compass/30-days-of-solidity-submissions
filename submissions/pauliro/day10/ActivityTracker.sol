// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.1;
/*
    Create a smart contract that logs user workouts and emits events when 
    fitness goals are reached — like 10 workouts in a week or 500 total minutes. 
    Users log each session (type, duration, calories), and the contract tracks progress. 
    Events use *indexed* parameters to make it easy for frontends or off-chain 
    tools to filter logs by user and milestone — just like a backend for a 
    decentralized fitness tracker with achievement unlocks.
*/

contract ActivityTracker {
// User profile 
    struct User {
        string name;
        uint256 weight; 
        bool registered;
    }
    //Workout data
    struct WorkoutActivity {
        uint256 timestamp;  
        string activityType; 
        uint256 duration;    // in seconds
        uint256 distance;    // in meters
    }
    
    mapping(address => User) public userProfiles;
    mapping(address => WorkoutActivity[]) private workoutHistory;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistance;

    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    event LogWorkout(address indexed userAddress, string activityType, uint256 timestamp, uint256 distance, uint256 duration);

    address public owner;
    constructor() {
        owner = msg.sender;
    }
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);

    modifier onlyRegistered() {
        require(userProfiles[msg.sender].registered, "The user is not registered");
    _;
    }
    // Register new user
    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].registered, "User already registered");
        userProfiles[msg.sender] = User({
            name: _name,
            weight: _weight,
            registered: true
        });
        // Emit registration event
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    // Update user weight
    function updateWeight(uint256 _newWeight) public onlyRegistered {
        User storage profile = userProfiles[msg.sender];
        // Check if weight loss  is 10% or more
        if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 10) {
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }
        profile.weight = _newWeight;
        // Log event: profile update 
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    // Log a workout activity
    function logWorkout(string memory _activityType, uint256 _duration, uint256 _distance) public onlyRegistered {
        // Create new workout activity
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });
     
        // Add workout to user's history
        workoutHistory[msg.sender].push(newWorkout);
        
        // Update stats
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender]+= _distance;
        
        // Emit workout logged event
        emit LogWorkout(msg.sender ,_activityType, _duration, _distance, block.timestamp);
        // Check for workout milestones
        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        }
        if (totalWorkouts[msg.sender] == 100) {
            emit MilestoneAchieved(msg.sender, "100 Workouts Completed", block.timestamp);
        }
        // Check for distance milestones
        if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        }
    }    
    // Get the number of workouts for a user
    function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
        return workoutHistory[msg.sender].length;
    }
}


