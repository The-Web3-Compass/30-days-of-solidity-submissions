// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleFitnessTracker {
    address public owner;

    //结构体
    struct UserProfile {
        string name;
        uint256 weight; //kg
        bool isRegistered;
        }

    struct WorkoutActivity {
        string activityType; //运动类型
        uint256 duration; //持续时间（s)
        uint256 distance; //距离（m）
        uint256 timestamp; //发生时间
    }
    mapping (address => UserProfile) public userProfiles; 
    //为每个用户（通过他们的地址）存储一份个人资料，userProfiles真正保存数据的“数据库”
    mapping (address => WorkoutActivity[]) private workoutHistory;
    //为每个用户保存一个锻炼日志数组
    mapping (address => uint256) public totalWorkouts;
    //跟踪每个用户记录了多少次锻炼
    mapping (address => uint256) public totalDistance;
    //跟踪用户覆盖的总距离

    
    //声明事件（广播出去）,当参数被标记为 indexed 时，你使它变得可搜索
    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event UserProfileUpdated(address indexed userAddress, uint256 weight, uint256 timestamp);
    event Workoutlogged(
        address indexed userAddress,
        string activityType,
        uint256 duration,
        uint256 distance,
        uint256 timestamp
    );
    event MilestoneAchieved(address indexed userAddress, string miletone, uint256 timestamp);

    constructor() {
        owner = msg.sender;
    }
    
    //修饰符：限制只有注册过的人能调用
    //.isRegistered 是访问结构体 UserProfile 里的一个布尔字段
    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    //注册新用户
    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");
        
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });
        
        //广播事件
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    //更新体重
    function updateWeight(uint256 _newweight) public onlyRegistered {
        //把当前用户的档案从数据库里取出来，放在变量 profile 里方便修改
        UserProfile storage profile = userProfiles[msg.sender];

        //检查体重是否有降低大于5%
        if (_newweight < profile.weight && (profile.weight - _newweight) * 100 / profile.weight >= 5) {
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }
        profile.weight = _newweight;
        
        //广播更新
        emit UserProfileUpdated(msg.sender, _newweight, block.timestamp);
    }

    //记录一次新的锻炼活动
    function logWorkout(
        string memory _activityType,
        uint256 _duration,
        uint256 _distance
    ) public onlyRegistered {
        //临时创建这个结构体，以便将它推入一个数组（workoutHistory[msg.sender]），不需要将它作为一个独立的变量永久存储
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });

        //将临时数据推入一个数组（workoutHistory[msg.sender]）
        workoutHistory[msg.sender].push(newWorkout);

        //更新总统计数据
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance;

        //广播锻炼事件
        emit Workoutlogged(
            msg.sender,
            _activityType,
            _duration,
            _distance,
            block.timestamp
        );

        // 检测并庆祝锻炼次数里程碑
        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        } //// else if当条件1不成立、条件2成立时执行
        else if (totalWorkouts[msg.sender] == 50) {
            emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }

        //检测并庆祝距离里程碑
        if (totalDistance[msg.sender] >100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
            //确保了我们只在用户跨过阈值的那一刻触发一次里程碑
        }
    }

    //告诉用户他们到目前为止记录了多少次锻炼
    function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
        return workoutHistory[msg.sender].length;//.length 的作用：返回这个数组的长度（元素个数）
    
    }

    }
