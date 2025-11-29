// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleFitnessTracker {

    address public owner;
    
    //用户资料结构体
    struct UserProfile {
        string name;
        uint256 weight;
        bool isRegistered;

    }

    //健身活动结构体
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

    event UserRegistered(addres indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(address indexed userAddress, string activityType, uint256 duration, uint256 distance, uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);

    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;

    }

    //注册用户
    function registerUser(string memory _name ,uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");

        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, _name, block.timestamp);

    }

    //更新体重
    function updateWeight(uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = userProfiles[msg.sender];

        if(_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight > = 5){
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }

        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);

    }

    //追踪每一次运动信息
    function logWorkout(string memory _activityType, uint256 _duration, uint256 _distance) public onlyRegistered{
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });

        workoutHistory[msg.sender].push(newWorkout);

        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance;

        emit WorkoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);

        if(totalWorkouts[msg.sender] == 10){
            emit MilestoneAchieved(msg.sender, "10 workouts completed", block.timestamp);
        }else if(totalWorkouts[msg.sender] == 50){
            emit MilestoneAchieved(msg.sender, "50 workouts completed", block.timestamp);
        }

        if(totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000){
            emit MilestoneAchieved(msg.sender, "100k total distance", block.timestamp);
        }

    }

    //获取用户锻炼次数
    function getUserWorkoutCount() public view onlyRegistered returns (uint256){
        return workoutHistory[msg.sender].length;

    }



}