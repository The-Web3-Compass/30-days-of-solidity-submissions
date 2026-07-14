// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleFitnessTracker {
    //用户信息
    struct UserProfile{
        string name;
        uint256 weight;
        bool isRegistered;
    }

    //锻炼的信息
    struct WorkoutActivity{
        string activityTpye;
        uint256 duration;
        uint256 distance ;
        uint256 timestamp;
    }

    mapping(address => UserProfile ) public userProfiles;
    mapping(address => WorkoutActivity[]) private workoutHistory;
    //记录用户的锻炼次数
    mapping(address => uint256 ) public totalWorkouts;
    
    //记录用户覆盖的总距离
    mapping(address => uint256 ) public totalDistance;

    event UserRegistered(address indexed userAddress ,string name ,uint256 timestamp);
    event ProfileUpdated(address indexed userAddress,uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(address indexed userAddress,string activityType ,uint256 duration,uint256 distance ,uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress ,string milestone ,uint256 timestamp);

    modifier  onlyRegistered(){
        require(userProfiles[msg.sender].isRegistered,"user not registered");
        _;
    }

//新会员注册
    function registerUser(string memory _name ,uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered,"user already registered");

            userProfiles[msg.sender] = UserProfile({
            name:_name,
            weight:_weight,
            isRegistered:true
        });

        emit UserRegistered(msg.sender,_name,block.timestamp);
    }

    //更新用户体重
    function updateWeight(uint256 _newWeight) public onlyRegistered{
        UserProfile storage profile = userProfiles[msg.sender];

        if(_newWeight < profile.weight && (profile.weight - _newWeight) *100 /profile.weight >= 5){
            emit MilestoneAchieved(msg.sender, "weight goal reached", block.timestamp);
        }

        profile.weight = _newWeight;
        emit  ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }  

    function logWorkout(string memory _activityType ,uint256 _duration, uint256 _distance) public onlyRegistered{
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityTpye :_activityType,
            duration: _duration,
            distance :_distance,
            timestamp :block.timestamp
        });

    workoutHistory[msg.sender].push(newWorkout);

    totalWorkouts[msg.sender]++;
    totalDistance[msg.sender]+= _distance;
        emit WorkoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);
  
     if (totalWorkouts[msg.sender] == 10) {
        emit MilestoneAchieved(msg.sender,"10 Workouts Completed",block.timestamp);
     }  else if(totalWorkouts[msg.sender] == 50){
        emit MilestoneAchieved(msg.sender,"50 workouts completed", block.timestamp);
     }  
      if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        }
    }

    function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
        return workoutHistory[msg.sender].length;
    }
}