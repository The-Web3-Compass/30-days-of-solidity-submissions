//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleFitnessTracker {     
    address public owner;     //定义一个公开变量 owner，储存合约拥有者的地址

    struct UserProfile {     //定义一个“结构体（struct）”，用于表示使用者资料
        string name;
        uint256 weight;
        bool isRegistered;
    }

struct WorkoutActivity {     //定义另一个结构体，用来存运动记录
//储存单次运动的资讯
    string activityType;
    uint256 duration;
    uint256 distance;
    uint256 timestamp;
}

mapping(address => UserProfile) public userProfiles;     //建立从“用户地址”到“用户资料”的映射表

mapping(address => WorkoutActivity[]) private workoutHistory;     //储存每个使用者的运动纪录数组

mapping(address => uint256) public totalWorkouts;     //记录使用者的运动次数
mapping(address => uint256) public totalDistance;     //记录使用者的累计距离

//定义事件（Event），用于区块链日志记录
event UserRegistered(address indexed userAddress, string name,uint256 timestamp);
event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
event WorkoutLogged(
    address indexed userAddress,
    string activityType,
    uint256 duration,
    uint256 distance,
    uint256 timestamp
);
event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);

//建构函数，只在部署合约时执行一次，把部署者设为 owner
constructor() {
    owner = msg.sender;
}

//定义修饰器 onlyRegistered，限制只有注册用户能执行的函数
modifier onlyRegistered() {
    require(userProfiles[msg.sender].isRegistered, "User not registered");
    _;
}

//让新用户注册资料
function registerUser(string memory _name, uint256 _weight) public {
    require(!userProfiles[msg.sender].isRegistered, "User already registered");

    userProfiles[msg.sender] = UserProfile({
        name: _name,
        weight: _weight,
        isRegistered: true
    });

    emit UserRegistered(msg.sender, _name, block.timestamp);
}

//更新使用者体重，并在达到减重目标时触发事件
function updateWeight(uint256 _newWeight) public onlyRegistered {
    UserProfile storage profile = userProfiles[msg.sender];

    if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5) {
        emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
    }

    profile.weight + _newWeight;

    emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);

}

//记录使用者的运动数据，并检查是否达成里程碑
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

if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
    emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
}

}

//回传使用者的运动纪录数量
function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
    return workoutHistory[msg.sender].length;
}

}