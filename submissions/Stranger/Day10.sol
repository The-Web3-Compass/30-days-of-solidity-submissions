// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleFitnessTracker {
    address public owner;

    // 用户信息结构体
    struct UserProfile {
        string name;
        uint256 weight; // 体重（单位：千克）
        bool isRegistered; // 是否注册
    }

    // 锻炼信息结构体
    struct WorkoutActivity {
        string activityType; //运动类型
        uint256 duration; // 锻炼持续时间（单位：秒）
        uint256 distance; // 距离（单位：米）
        uint256 timestamp; // 锻炼时间戳
    }

    // 存储用户信息、锻炼历史、总锻炼次数、总距离的映射
    mapping(address => UserProfile) public userProfiles;
    mapping(address => WorkoutActivity[]) public workoutHistory;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistance;

    // 定义事件, 包括用户注册、用户信息更新、锻炼日志、里程碑达成事件
    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(address indexed userAddress, string activityType, uint256 duration, uint256 distance, uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "User not Registered");
        _;
    }

    // 注册新用户
    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");

        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });

        // 触发用户注册事件
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    // 更新用户体重
    function updateWeight(uint256 _newWeight) public onlyRegistered {
        uint256 oldWeight = userProfiles[msg.sender].weight;
        userProfiles[msg.sender].weight = _newWeight;

        // 检查是否达成减重目标
        if (_newWeight < oldWeight && (oldWeight - _newWeight) * 100 / oldWeight >= 5) {
            emit MilestoneAchieved(msg.sender, "Weight Goal Achieved", block.timestamp);
        }

        // 触发用户信息更新事件
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    // 记录锻炼日志
    function logWorkout(string memory _activityType, uint256 _duration, uint256 _distance) public onlyRegistered {
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });

        // 新增锻炼记录
        workoutHistory[msg.sender].push(newWorkout);

        // 更新统计数据
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance;

        // 触发日志记录事件
        emit WorkoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);

        // 检查是否达成锻炼次数里程碑
        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "10 Workouts Milestone Achieved", block.timestamp);
        } else if (totalWorkouts[msg.sender] == 50) {
            emit MilestoneAchieved(msg.sender, "50 Workouts Milestone Achieved", block.timestamp);
        }
        
        // 检查是否达成锻炼距离里程碑
        if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] < 100000 + _distance) {
            emit MilestoneAchieved(msg.sender, "100km Milestone Achieved", block.timestamp);
        }
    }
}