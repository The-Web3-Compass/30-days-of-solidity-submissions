//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract activityTracer {
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
    
   //event相当于先记录一下 用于后面emit 
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
        });
        
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }
    
   
    function updateWeight(uint256 _newWeight) public onlyRegistered {

        UserProfile storage profile = userProfiles[msg.sender];   //这里用storage是因为userProfiles[msg.sender] 是一个状态变量，是储存在区块链上的“数据库”，需要彻底修改

        if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5) {
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }
       
       profile.weight=_newWeight;

       emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

  function logWorkout(string memory _activityType, uint256 _duration, uint256 _distance) public onlyRegistered{
        
        WorkoutActivity memory newWorkout = WorkoutActivity({     //这里用memory是这个变量 newWorkout 是临时创建的结构体，只用于 本函数内部使用。它之后会被 .push() 添加到 workoutHistory[msg.sender] 这个 真正的存储数组中。所以这里用 memory，表示“临时变量，稍后会用”。


            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });

        workoutHistory[msg.sender].push(newWorkout);

        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance;

        emit WorkoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp); 


      if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        } else if (totalWorkouts[msg.sender] == 50) {
            emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }

    //确保这是第一次里程碑
      if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        }
    }
   
   
   function getWorkoutCount() public view onlyRegistered returns(uint256){
      return workoutHistory[msg.sender].length;
     
   }



}
       
