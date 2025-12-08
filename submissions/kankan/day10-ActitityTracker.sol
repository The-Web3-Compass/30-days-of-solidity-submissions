// SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

contract SimpleFitnessTracker{

    //基本用户信息
    struct UserProfile{
        string name;//姓名
        uint256 weight;//体重
        bool isRegistered;//是否已注册
    }

    //每个锻炼情况信息
    struct WorkoutActivity{
        string activityType;// 活动类型
        uint256 duration;// 持续多长时间
        uint256 distance;// 用户走了多远
        uint256 timestamp;//何时发生的
    }

    mapping (address=>UserProfile) public UserProfiles;//存储每个用户的配置文件
    mapping (address=>WorkoutActivity[]) private workoutHistory;//为每个用户保留一系列锻炼日志
    mapping (address=>uint256) public totalWorkouts;//跟踪每个用户记录的体能训练次数
    mapping (address=>uint256) public totalDistance;//跟踪用户覆盖的总距离

    // 声明一些事件
    event UserRegistered(address indexed userAddress,string name,uint256 timestamp);
    event ProfileUpdated(address indexed userAddress,uint256 newWeight,uint256 timestamp);
    event WorkoutLogged(address indexed userAddress, string activityType,uint256 duraction,uint256 distance,uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress,string milestone,uint256 timestamp);

    modifier onlyRegistered(){
        require(UserProfiles[msg.sender].isRegistered,"User not registered");
        _;
    }

    // 注册用户
    function registerUser(string memory _name,uint256 _weight) public {
        require(!UserProfiles[msg.sender].isRegistered,"User already registered");

        UserProfiles[msg.sender] = UserProfile({
            name:_name,
            weight:_weight,
            isRegistered:true
        });

        emit UserRegistered(msg.sender, _name, block.timestamp);
    }
    // 更新当前体重
    function updateWeight(uint256 _newWeight) public  onlyRegistered{
        UserProfile storage profile = UserProfiles[msg.sender];
        if(_newWeight<profile.weight&&(profile.weight-_newWeight)*100/profile.weight>=5){
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }
        profile.weight=_newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    //跟踪每次重复、跑步和骑行
    function logWorkout(
        string memory _activityType,
        uint256 _duration,
        uint256 _distance
    ) public onlyRegistered{
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });
        
        workoutHistory[msg.sender].push(newWorkout);
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender]+=_distance;

        emit WorkoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);

        if(totalWorkouts[msg.sender]==10){
            emit MilestoneAchieved(msg.sender, "10 Workout Completed", block.timestamp);
        }
        else if(totalWorkouts[msg.sender]==50){
            emit MilestoneAchieved(msg.sender, "50 Workout Completed", block.timestamp);
        }

        if(totalDistance[msg.sender]>=10000&&totalDistance[msg.sender]-_distance<100000){
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        }
    }

}