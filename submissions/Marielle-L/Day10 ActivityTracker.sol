//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract SimpleFitnesstTracker {
    address public owner;

    struct UserProfile{
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
    event ProfileUpdated(address indexed userAddress,uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(
        address indexed userAddress,
        string activityType,  
        uint256 duration,
        uint256 distance,     
        uint256 timestamp
    );
    event MilestoneAchieved(address indexed userAddress,string milestone,uint timestamp);
        
    constructor() {
        owner = msg.sender;
    
    }

    modifier onlyRegistered(){
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }
    
    function registerUser (string memory _name , uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");

        userProfiles[msg.sender] = UserProfile({
            name: _name, 
            weight :_weight,
            isRegistered: true
        });

        emit UserRegistered(msg.sender ,_name, block.timestamp);

    }
    
    function updateWeight(uint256 _newWeight)  public onlyRegistered {
        UserProfile storage profile = userProfiles[msg.sender];

        if (_newWeight < profile.weight && (profile.weight - _newWeight)* 100/ profile.weight >= 5){
            emit MilestoneAchieved(msg.sender,"Weight Goal Reached", block.timestamp);
        }

        profile.weight - _newWeight;

        emit ProfileUpdated(msg.sender,_newWeight ,block.timestamp);

    } 

    function logWorkout(
        string memory _activityType,
        uint256 _duration, 
        uint256 _distance
    ) public onlyRegistered{
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType:_activityType , 
            duration : _duration,
            distance: _distance,   
            timestamp: block.timestamp  
        });
        
        workoutHistory[msg.sender].push(newWorkout);

        totalWorkouts[msg.sender] ++;
        totalDistance[msg.sender] += _distance;

        emit WorkoutLogged ( 
            msg.sender,
            _activityType ,
            _duration  , 
            _distance,
            block.timestamp
        );

        if (totalWorkouts[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender,"100K Total Distance ", block.timestamp);
        }

    }

    function getUserWorkoutCourt() public view onlyRegistered returns (uint256){
        return workoutHistory[msg.sender].length;
    }
}
