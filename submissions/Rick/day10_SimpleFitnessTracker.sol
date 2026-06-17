// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleFitnessTracker{

    address public owner;
    
    /*
        定义类 用户资料

        struct 等同于java中pojo实体类简化版，主要有以下区别：
        没有set get 或其他声明的方法
        字段没有public private等权限声明
        不能继承
    */
    struct UserProfile {
        string name;
        uint256 weight; 
        bool isRegistered;
    }
    
    // 锻炼记录
    struct WorkoutActivity {
        string activityType; 
        uint256 duration;    
        uint256 distance;    
        uint256 timestamp;   
    } 

    // 用户地址-> 用户资料
    mapping(address => UserProfile) public userProfiles;
    // 用户地址-> 锻炼记录
    mapping(address => WorkoutActivity[]) private workoutHistory;
    // 记录锻炼次数
    mapping(address => uint256) public totalWorkouts;
    // 记录锻炼跑步里程
    mapping(address => uint256) public totalDistance;
    
    /*
        定义事件

        区块链的每个区块都有一个日志区，用于保存event记录下来的历史事件日志
        不可以被智能合约读取，主要用于链下程序监听和查询使用
        不可篡改，永久保存在区块中

        event 是用来在区块链上记录日志信息的，
        1.方便前端（如 DApp、ethers.js、web3.js）去监听和读取。
        2.节省gas，直接记录日志，不增加智能合约复杂度

        index：event中便于快速检索的字段
        一个事件最多三个index
        不能给mapping  struct添加index
        bytes string添加index不是添加原字段而是添加了Keccak256哈希值
    */
    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(address indexed userAddress,  string activityType, uint256 duration, uint256 distance, uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);
    

    constructor() {
        owner = msg.sender;
    }

    // 校验 必须是注册者
    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    /* 
        注册用户
        emit 向链上日志系统写入事件数据
    */
    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");
        
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    // 更新体重，超过5%才会触发MilestoneAchieved
    function updateWeight(uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = userProfiles[msg.sender];
        if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5) {
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }
        
        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    // 查询运动次数
    function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
        return workoutHistory[msg.sender].length;
    }

    // 新增运动记录
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
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        } else if (totalWorkouts[msg.sender] == 50) {
            emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }
    
        if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        }
    }
}