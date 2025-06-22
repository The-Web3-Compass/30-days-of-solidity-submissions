// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

contract ActivityTracker{
        
    struct UserProfile {
        string name;
        // kg
        uint256 weight; 
        bool isRegistered;
    }


    struct WorkoutActivity {
        string activityType;
        // in seconds
        uint256 duration; 
        // in meters
        uint256 distance; 
        uint256 timestamp;
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(address => WorkoutActivity[]) private workoutHistory;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistance;

    /**
    Event:When something important happens in your contract, 
    you can emit one of these events, and it’ll be recorded in the transaction logs.  
    indexed:This means you can filter logs in your frontend based on that specific value. 
    And you can only index up to three parameters in a single event 
    */
    event UserRegistered(address indexed userAddress,string name,uint256 timestamp);
    event ProfileUpdated(address indexed userAddress,uint256 weight,uint256 timestamp);
    event WorkoutLogged(address indexed userAddress,string activityType,uint256 duration,uint distance,uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress,string milestone,uint256 timestamp);

    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }   

    function registerUser(string memory _name, uint256 _weight) public onlyRegistered{

        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });

         emit UserRegistered(msg.sender, _name, block.timestamp);

    }

    function updatWeight(uint256 _newWeight) public onlyRegistered {
        // This is a reference to the user’s profile stored on the blockchain.
        // memory it'd only be working with a temporary copy.
        UserProfile storage profile = userProfiles[msg.sender];
        
        if(_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5){
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }   

        profile.weight = _newWeight;

        emit ProfileUpdated(msg.sender,_newWeight,block.timestamp);

    }


    function logWorkout( string memory _activityType,
        uint256  _duration,
        uint256  _distance) public onlyRegistered{

        // WorkoutActivity memory workActivity =  WorkoutActivity({
        //     activityType: _activityType,
        //     duration: _duration,
        //     distance: _distance,
        //     timestamp: block.timestamp
        // });

        workoutHistory[msg.sender].push({
            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance;

        emit WorkoutLogged(msg.sender,_activityType,_duration,_distance,block.timestamp);


        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        } else if (totalWorkouts[msg.sender] == 50) {
            emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }

        if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        }


    }

    function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
        return workoutHistory[msg.sender].length;
    }




}