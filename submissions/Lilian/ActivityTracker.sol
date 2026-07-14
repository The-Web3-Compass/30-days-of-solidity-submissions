// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleFitnessTracker{
    address public owner;

    struct userprofile{//记录用户信息
        string name;
        uint256 weight;
        bool isRegistered;
    }

    struct WorkoutActivity{//记录锻炼数据
        string activitytype;
        uint256 duration;
        uint256 distance;
        uint256 timestamp;
    }

    mapping(address=>userprofile) public_userprofile;//存储用户个人资料
    mapping(address=>WorkoutActivity[])private workouthistory;//保存锻炼日志
    mapping (address=>uint256)public totalWorkouts;
    mapping (address=>uint256)public totalDistance;

    event UserRigistered(address indexed useraddress,string name,uint256 timestamp);
    event Profileupdated(address indexed useraddress,uint256 newweight,uint256 timestamp);
    event WorkoutLogged(address indexed useraddress,string activityType,uint256 duration,uint256 timestamp);//为前端提供信息
    event MilestoneAchieved(address indexed useraddress,string milestone,uint256 timestamp);
    
    constructor(){
    owner=msg.sender;
}
modifier onlyRegistered(){
    require(userProfile[msg.sender].isRegistered,"User not registered");
    _;//确保调用者已注册
}

function registerUser (string memory_name,uint256 weight)public {
    require(!Userprofiles[msg.sender].isRegistered,"User already registered");

    userprofiles[msg.sender]=Userprofile({
        name:_name,
        weight:_weight,
        isRegistered:true
    });//存储到映射里面

    emit UserRigistered(msg.sender, _name, block.timestamp);//告诉区块链注册者和时间
}
function updateweight (uint256 _newweight)public onlyRegistered{
    userprofile storage profile =Userprofiles[msg.sender];//访问个人资料

    if (_newweight<profile.weight && (profile.weight - _newweight)*100/profile.weight>=5) {//检查有没有达到目标体重
        emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);//触发前端达到目标
    }
    profile.weight=_newWeight;//更新新体重
    emit Profileupdated(msg.sender, _newweight, block.timestamp);//刷新进度
}
function logWorkout(
    string memory _activityType,
    uint256 duration,
    uint256 distance //接受锻炼细节
)public onlyRegistered{
    WorkoutActivity memory newWorkout = WorkoutActivity({
        activityType:_activityType,
        duration:_duration,
        distance:_distance,
        timestamp:block.timestamp
    });//对象信息
    workouthistory[msg.sender].push(workout);//把锻炼存储在用户个人记录里
    totalWorkouts[msg.sender]++;//用户完成了多少锻炼
    totalDistance[msg.sender]+=distance;//完成了多少距离
    emit WorkoutLogged(msg.sender, _activityType, _duration, block.timestamp);//前端需要新反馈的信息

    if (totalWorkouts[msg.sender]==10){
        emit MilestoneAchieved(msg.sender, "10 Workouts completed", block.timestamp);
    }else if (totalWorkouts[msg.sender]==50){
        emit MilestoneAchieved(msg.sender, "50 Workouts completed", block.timestamp);//检查有没有达到10天或者20天
    }

    function getuserWorkoutCount()public view onlyRegistered returns (uint256){
        return workouthistory[msg.sender].length;//一个只读函数
    }
}