// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleFitnessTracker {

    address public owner;

    struct UserProfile {
        string name; // 名字
        uint256 weight; // 体重
        bool isRegistered; // 是否已注册
    }

    struct WorkoutActivity {
        string activityType;  // 活动类型
        uint256 duration; // 持续时间
        uint256 distance; // 走了多远
        uint256 timestamp; // 何时发生
    }

    mapping(address => UserProfile) public userProfiles; // 每个用户的数据
    mapping(address => WorkoutActivity[]) private workoutHistory; // 每个用户保留锻炼日志
    mapping(address => uint256) public totalWorkouts; // 每个用户总锻炼次数
    mapping(address => uint256) public totalDistance; // 每个用户的总距离

    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(address indexed userAddress, string activityType, uint256 duration, uint256 distance, uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);

    constructor(){
        owner = msg.sender;
    }

    modifier onlyRegistered(){
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    // 添加新成员
    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    // 更新用户的体重
    function updataWeight(uint256 _newWeight) public onlyRegistered{
        UserProfile storage profile = userProfiles[msg.sender];
        // 体重缩减百分之5或者更多， 事件提醒
        if(_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5){
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }
        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    // 跟踪记录用户每次锻炼
    function logWorkout(string memory _activityType, uint256 _duration, uint256 _distance)public onlyRegistered{
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType: _activityType, // 什么运动
            duration: _duration, // 持续时间
            distance: _distance, // 距离
            timestamp: block.timestamp // 时间戳
        });
        workoutHistory[msg.sender].push(newWorkout);
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance; // 保留运动总时长及距离

        // 存储之后通知前端数据更新了
        emit WorkoutLogged(
            msg.sender,
            _activityType,
            _duration,
            _distance,
            block.timestamp
        );

        // 锻炼10次或50次 历程 进行事件触发 告诉前端
        if(totalWorkouts[msg.sender] == 10){
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        }else if(totalWorkouts[msg.sender] == 50){
            emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }
        // 100k公里达成 进行事件触发 告诉前端
        if(totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000){
            emit MilestoneAchieved(msg.sender, "100K Total Distance",block.timestamp);
        }
    }
    // 获取进行了多少次锻炼
    function getUserWorkoutCount() public view onlyRegistered returns (uint256){
        return workoutHistory[msg.sender].length;
    }
}