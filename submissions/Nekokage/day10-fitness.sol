//SPDX-License-Identifier: MIT
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
    
    event UserRegistered(address userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address userAddress, uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(address userAddress, string activityType, uint256 duration, uint256 distance, uint256 timestamp);
    event MilestoneAchieved(address userAddress, string milestone, uint256 timestamp);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "请先注册");
        _;
    }
    
    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "用户已注册");
        
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });
        
        // 触发注册事件
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }
    
    // 更新体重
    function updateWeight(uint256 _newWeight) public onlyRegistered {
        // 获取用户档案
        UserProfile storage profile = userProfiles[msg.sender];
        
        // 检查是否达到减重目标（减少5%以上）
        if (_newWeight < profile.weight) {
            uint256 weightLoss = profile.weight - _newWeight;
            uint256 lossPercentage = (weightLoss * 100) / profile.weight;
            
            if (lossPercentage >= 5) {
                emit MilestoneAchieved(msg.sender, "达到减重目标", block.timestamp);
            }
        }
        
        // 更新体重
        profile.weight = _newWeight;
        
        // 触发更新事件
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }
    
    // 记录运动
    function logWorkout(
        string memory _activityType,
        uint256 _duration,
        uint256 _distance
    ) public onlyRegistered {

        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });
        
        workoutHistory[msg.sender].push(newWorkout);
        
        // 更新统计数据
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance;
        
        emit WorkoutLogged(
            msg.sender,
            _activityType,
            _duration,
            _distance,
            block.timestamp
        );
        
        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "完成10次运动", block.timestamp);
        } else if (totalWorkouts[msg.sender] == 50) {
            emit MilestoneAchieved(msg.sender, "完成50次运动", block.timestamp);
        }
        
        if (totalDistance[msg.sender] >= 100000) {
            emit MilestoneAchieved(msg.sender, "总距离达到100公里", block.timestamp);
        }
    }
    
    function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
        return workoutHistory[msg.sender].length;
    }
    
    function getUserTotalDistance() public view onlyRegistered returns (uint256) {
        return totalDistance[msg.sender];
    }
    
    function getUserInfo() public view onlyRegistered returns (string memory, uint256) {
        UserProfile memory profile = userProfiles[msg.sender];
        return (profile.name, profile.weight);
    }
}