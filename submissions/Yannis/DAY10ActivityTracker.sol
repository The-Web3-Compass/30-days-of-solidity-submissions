// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleFitnessTracker {
    address public owner; 
    
    
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
    
    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(
        address indexed userAddress, 
        string activityType, 
        uint256 duration, 
        uint256 distance, 
        uint256 timestamp
    );
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);
    
    constructor() {
        owner = msg.sender; 
    }
    
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }
    
    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }
    
    
    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");
        require(bytes(_name).length > 0, "Name required"); 
        require(_weight > 0, "Weight must be > 0"); 
        
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });
        
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }
    
    
    function updateWeight(uint256 _newWeight) public onlyRegistered {
        require(_newWeight > 0, "Weight must be > 0"); 
        UserProfile storage profile = userProfiles[msg.sender];
        
        
        if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5) {
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }
        
        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }
    
    
    function logWorkout(
        string memory _activityType,
        uint256 _duration,
        uint256 _distance
    ) public onlyRegistered {
        require(bytes(_activityType).length > 0, "Activity type required"); 
        require(_duration > 0, "Duration must be > 0"); 
        
        
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });
        
        uint256 prevTotalDistance = totalDistance[msg.sender]; 
        workoutHistory[msg.sender].push(newWorkout);
        
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] = prevTotalDistance + _distance;
        
        emit WorkoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);
        
      
        uint256 tw = totalWorkouts[msg.sender];
        if (tw == 10) {
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        } else if (tw == 50) {
            emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }
        
        
        if (prevTotalDistance < 100000 && totalDistance[msg.sender] >= 100000) {
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        }
    }
    
    
    function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
        return workoutHistory[msg.sender].length;
    }
    
    
    function getWorkoutByIndex(uint256 index) public view onlyRegistered returns (
        string memory activityType,
        uint256 duration,
        uint256 distance,
        uint256 timestamp
    ) {
        require(index < workoutHistory[msg.sender].length, "Index out of range");
        WorkoutActivity storage w = workoutHistory[msg.sender][index];
        return (w.activityType, w.duration, w.distance, w.timestamp);
    }
    
    
    function getMyProfile() public view onlyRegistered returns (string memory name, uint256 weight) {
        UserProfile storage p = userProfiles[msg.sender];
        return (p.name, p.weight);
    }
    
    
    function getTotals(address user) public view returns (uint256 workouts, uint256 distance) {
        return (totalWorkouts[user], totalDistance[user]);
    }
    
    
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        owner = newOwner;
    }
}
