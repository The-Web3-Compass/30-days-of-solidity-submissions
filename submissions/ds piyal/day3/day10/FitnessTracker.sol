// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ActivityTracker{
    struct UserProfile{
        string name;
        uint256 weight;
        bool isRegistered;
    }
    struct WorkoutActivity{
        string WorkoutType;
        uint256 duration;
        uint256 distance;
        uint256 timestamp;
    }
    mapping(address => UserProfile) public UserProfiles;
    mapping(address => WorkoutActivity[]) public WorkoutHistory;
    mapping(address => uint256) public TotalWorkouts;
    mapping(address => uint256) public TotalDistance;

    event UserRegistered(address indexed UserAddress,string name,uint256 timestamp);
    event ProfileUpdated(address indexed UserAddress,uint256 weight,uint256 timestamp);
    event WorkoutLogged(address indexed UserAddress,string ActivityType,uint256 duration,uint256 distance,uint256 timestamp);
    event MilestoneAchieved(address indexed UserAddress,string milestone,uint256 timestamp);

    modifier onlyRegistered{
        require(!UserProfiles[msg.sender].isRegistered,"User not registered");
        _;
    }

    function registerUser(string memory _name,uint256 _weight) public {
        require(!UserProfiles[msg.sender].isRegistered,"Already registered");

        UserProfiles[msg.sender]= UserProfile({
             name:_name , 
             weight:_weight, 
             isRegistered:true 
             });
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }
    function updateWeight(uint256 _newWeight) public onlyRegistered{
        UserProfile storage profile=UserProfiles[msg.sender];
        if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5){
            emit MilestoneAchieved(msg.sender, "Weight loss of 5% achieved!",block.timestamp);
        }
        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender , _newWeight, block.timestamp);
    }
        
        function logWorkout(string memory _activityType,uint256 _duration,uint256 _distance) public onlyRegistered{
            WorkoutActivity memory newWorkout=WorkoutActivity({
                WorkoutType: _activityType,
                duration:_duration, 
                distance:_distance,
                timestamp:block.timestamp
            });
            WorkoutHistory[msg.sender].push(newWorkout);
        TotalWorkouts[msg.sender]++;
        TotalDistance[msg.sender] += _distance;

        emit WorkoutLogged(msg.sender,_activityType , _duration, _distance,block.timestamp);
      
      if (TotalWorkouts[msg.sender]==10){
        emit MilestoneAchieved(msg.sender,"10 workouts completed!", block.timestamp );
        }else if (TotalWorkouts[msg.sender]==50){
            emit MilestoneAchieved(msg.sender, "50 workouts completed!",block.timestamp);

        }
        if (TotalDistance[msg.sender] >= 100000 && TotalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100K total distance covered!", block.timestamp);

        }
        }

        function getUserWorkoutCount() public onlyRegistered view returns(uint256) {
            return WorkoutHistory[msg.sender].length;
        }
        
    }