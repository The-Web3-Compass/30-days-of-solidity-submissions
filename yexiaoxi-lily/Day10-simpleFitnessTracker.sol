// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract simpleFitnessTracker{
    address public owner;
    //结构体 每个注册地址储存
    struct UserProfile{
        string name;
        uint256 weight;
        bool isRegistered;
    }

    struct WorkoutActivity{
        string activityType;
        uint256 duration;  //持续时间 in seconds
        uint256 distance;  //距离  in meters
        uint256 timestamp;
    }

    mapping (address =>UserProfile) public userProfiles;   //注册人员
    mapping (address =>WorkoutActivity[]) private workoutHistory;  //运动日志记录
    mapping (address =>uint256) public totalWorkouts;  //总运动次数
    mapping (address =>uint256) public totalDistance;  //总距离
    //注册人员 事件
    event userRegistered(address indexed userAddress,string name,uint256 timestamp);
    //新体重  时间
    event profileUpdated(address indexed userAddress,uint256 newWeight,uint256 timestamp);
    event Workoutlogged(
        address indexed userAddress,
        string activityType,
        uint256 duration,
        uint256 distance,
        uint256 timestamp
    );
    event MilestoneAchived(address indexed userAddress,string milestone,uint256 timestamp);

    constructor(){
        owner =msg.sender;
    }
    //判定注册
    modifier onlyRegistered(){
        require(userProfiles[msg.sender].isRegistered,"User not registered");
        _;
    }
    //加入队伍，添加信息进映射中
    function registerUser(string memory _name,uint256 _weight) public{
        require(!userProfiles[msg.sender].isRegistered,"User already registered");
        //用户信息的地址映射 等于 用户信息结构体（一段信息）
        userProfiles[msg.sender] =UserProfile({
            name:_name,
            weight:_weight,
            isRegistered:true
        });
    }
    //更新体重
    function updateWeight(uint256 _newWeight) public onlyRegistered{
        //创建指向存储在区块链上个人资料的引用，指向合约存储中已经存在的数据，并要求永久储存
        //用户映射= 用户结构 存储profile
        UserProfile storage profile = userProfiles[msg.sender];
        //体重变化判断
        if (_newWeight < profile.weight && (profile.weight-_newWeight)*100/profile.weight >=5){
            emit MilestoneAchived(msg.sender,"Weight Goal Reached",block.timestamp); 
        }
        profile.weight =_newWeight;
        //触发新体重事件
        emit profileUpdated(msg.sender,_newWeight, block.timestamp);
    }
    //锻炼记录,并通过结构更新映射数据，同时做判定触发成就事件
    function logWorkout(
        string memory _activityType,
        uint256 _duration,
        uint256 _distance
    ) public onlyRegistered{
        //结构
        WorkoutActivity memory newWorkout =WorkoutActivity({
            activityType:_activityType,
            duration:_duration,
            distance:_distance,
            timestamp:block.timestamp
        });

        //添加进日志数组
        workoutHistory[msg.sender].push(newWorkout);
        totalWorkouts[msg.sender]+=1;
        totalDistance[msg.sender]+=_distance;

        //触发事件
        emit Workoutlogged(msg.sender,_activityType,_duration,_distance,block.timestamp);

        //判定触发成就
        if (totalWorkouts[msg.sender] ==10){
            emit MilestoneAchived(msg.sender, "10 workouts completed", block.timestamp);
        }else if(totalWorkouts[msg.sender] ==50){
            emit MilestoneAchived(msg.sender, "50 workouts completed", block.timestamp);
        }
        if (totalDistance[msg.sender]>=100000 && totalDistance[msg.sender] -_distance <100000){
            emit MilestoneAchived(msg.sender,"100k total distance",block.timestamp);
        }
    }

    function getUserWorkoutCount()public view onlyRegistered returns (uint256){
        return workoutHistory[msg.sender].length;
    }

}
//owner:0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
//jack:0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
//jack:0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
