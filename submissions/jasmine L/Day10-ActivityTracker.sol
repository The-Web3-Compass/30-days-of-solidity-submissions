// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ActivityTracker{
    struct UserProfile{//用户信息
        string name;
        uint256 weight;
        bool isRegistered;
    }
    struct WorkoutActivity {//一次活动信息
        string activityType;
        uint256 duration;
        uint256 distance;
        uint256 timestamp;
    }

    mapping (address => UserProfile) public userProfile;
    mapping (address => WorkoutActivity[]) private workoutHistory;

    mapping(address => uint256) public totalWorkouts;//是否触发事件
    mapping(address => uint256) public totalDistance;
    
    event UserRegistered(address indexed _address, string _name, uint256 _timestamp);
    event ProfileUpdated(address indexed  _address, uint256 _newWeight, uint256 _timestamp);

    event WorkoutActivityLogged(
        address indexed _address,
        string _activityType,
        uint256 _duration,
        uint256 _distance,
        uint256 timestamp);

     event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);

    modifier OnlyRegistered(){
        require(userProfile[msg.sender].isRegistered, "Not Registered!");
        _;
    }

    function registerUser(string memory _name, uint256 _weight) public{
        userProfile[msg.sender] = UserProfile({
            name:_name,
            weight:_weight,
            isRegistered:true});
        emit UserRegistered(msg.sender, _name, block.timestamp);//用的区块时间戳
    }

    function updateWeight(uint256 _weight) public OnlyRegistered{
        UserProfile storage profile = userProfile[msg.sender];//创建引用
        if(_weight < profile.weight && (profile.weight - _weight)*100/profile.weight >=5){
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }
        profile.weight = _weight;
        emit ProfileUpdated(msg.sender, _weight, block.timestamp);

    }

    function logWorkout(string memory _activityType, uint256 _duration, uint256 _distance) public OnlyRegistered{
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType:_activityType,
            duration: _duration,
            distance: _distance,
            timestamp:block.timestamp
            });
        workoutHistory[msg.sender].push(newWorkout);

        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance;

        emit WorkoutActivityLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);

        if(totalDistance[msg.sender]>=100000){
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        }

        if(totalWorkouts[msg.sender] == 10){
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        }else if(totalWorkouts[msg.sender] == 50){
            emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }


    }

    function getUserWorkoutCount() public view OnlyRegistered returns(uint256){
         return workoutHistory[msg.sender].length;
    }

}