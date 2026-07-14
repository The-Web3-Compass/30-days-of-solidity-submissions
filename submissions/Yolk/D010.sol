//SPDX-License-Identifier： MIT
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleFitnessTracker{//events, emit logs日志
    struct UserProfile{
        string name;
        uint256 weight;//in kg
        bool isRegistered;
    }
    struct WorkoutActivity {
        string activityType;
        uint256 duration;//in seconds
        uint256 distance;//in meters
        uint256 timestamp;
    }
    //映射
    mapping(address => UserProfile) public userProfiles;
    mapping(address => WorkoutActivity[]) private workoutHistory;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistance;

    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(address indexed userAddress, string activityType, uint256 duration, uint256 distance, uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);
    //emit 发出
    //indexed 搜索
    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }
    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, _name, block.timestamp);

    }
    emit UserRegistered(msg.sender, name, block.timestamp);
    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    //发出事件确实会消耗一点 Gas（因为日志被写入区块链），但它们比在链上存储数据便宜得多。
    //发出事件是智能合约暴露数据最节省 Gas 的方式之一。
    function updateProfile(uint256 _newWeight) public onlyRegistered {
        userProfile storage profile = userProfiles[msg.sender];//访问资料
        if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5){//检查
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
            profile.weight = _newWeight;//更新体重
            emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);//发出
        }

        function logWorkout(
            string memory _activityType,
            uint256 _duration,
            uint256 _distance
        ) public onlyRegistered {
            //create new workout activity
            WorkoutActivity memory newWorkout = WorkoutActivity({
                activityType: _activityType,
                duration: _duration,
                distance: _distance,
                timestamp: block.timestamp
            });
            //add to user's workout history
            workoutHistory[msg.sender].push(newWorkout);
            //update total stats
            totalWorkouts[msg.sender]++;
            totalDistance[msg.sender] += _distance;
            //emit workout logged event
            emit WorkoutLogged(
                msg.sender,
                _activityType,
                _duration,
                _distance,
                block.timestamp
            );
            //check for workout count milestones
            if (totalWorkouts[msg.sender] == 10){
                emit MilestoneAchieved(msg.sender, "10 Workouts", block.timestamp);
            } else if (totalWorkouts[msg.sender] == 50){
                emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp); 
            }//- `storage` 是持久的——它存在于区块链上，读/写都需要消耗 Gas。 `memory` 是临时的——它只在函数调用期间存在，而且便宜得多。
            //check for distance milestones
            if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
                emit MilestoneAchieved(msg.sender, "100k Total Distance", block.timestamp);//检查并庆祝
            }
            function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
                return workoutHistory[msg.sender].length;
            }
        }


}