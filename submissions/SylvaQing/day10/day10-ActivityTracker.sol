
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleFitnessTracker {

    struct UserProfile{
        string name;
        uint256 weight;
        bool isReged;
    }
    struct WorkoutActivity{
        string activityType;
        uint256 duration;//单位s
        uint256 distance;//单位m
        uint256 timestamp;
    }
    
    mapping (address => UserProfile) public users;
    mapping ( address => WorkoutActivity[] ) public userWorkouts;
    mapping ( address => uint256 ) public totalWorkouts;
    mapping (address => uint256) public totalDistance;
    
    //事件声明 
    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(address indexed userAddress, string activityType, uint256 duration, uint256 distance, uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);
    
    modifier onlyReged(){
        require(users[msg.sender].isReged, "User not registered");
        _;
    }
    //注册
    function regUser(string memory  _name,uint256 _weight)public {
        require(!users[msg.sender].isReged, "User not registered");
        users[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isReged:true
        });
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }
    // 更新体重
    function updateWeight(uint256 _newWeight)public onlyReged{
        UserProfile storage profile =users[msg.sender]; //已经存在的数据要改原本的而非副本
        //体重下降-奖励机制（后续或许可以调整为动态的？）（条件自己设定）
        if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5) {
        emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }
        //更新
        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);

    }
    //记录锻炼
    function logWorkOut(
        string memory _activityType,
        uint256 _duration,
        uint256 _distance
    )public onlyReged {
        WorkoutActivity memory newWorkout=WorkoutActivity(
            {
                activityType:_activityType,
                duration:_duration,
                distance:_distance,
                timestamp:block.timestamp
            }
        );
        userWorkouts[msg.sender].push(newWorkout);
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance;
        emit WorkoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);
        //检查里程碑
        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        } else if (totalWorkouts[msg.sender] == 50) {
             emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }
        if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        }
    }
    //查询
    function getUserWorkoutCount()public view onlyReged returns (uint256){
        return userWorkouts[msg.sender].length;
    }
}