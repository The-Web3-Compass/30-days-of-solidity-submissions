// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;

contract SimpleFitnessTracker{
    struct UserProfile{
        string name;
        uint256 weight; //in kg
        bool isRegistered;
    }

    struct WorkoutActivity{
        string activityType;
        uint duration; //in secends
        uint256 distance; //in meters
        uint256 timestamp;
    }

    //有了数据结构，可以使用mapping将它们连接起来
    mapping(address => UserProfile) public userProfiles;
    mapping(address => WorkoutActivity[]) private workoutHistory;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistance;

    //声明事件，将充当前端可以监听的信号
    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    //event WorkoutLogged(address indexed userAddress, string activityType, uint256 duration, uint distance, uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);
    event WorkoutLogged(
        address indexed userAddress,  //indexed索引，使其可以搜索
        string activityType,
        uint256 duration,
        uint256 distance,
        uint256 timestamp
    );

    modifier onlyRegistered(){
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    function registerUser(string memory _name, uint256 _weight) public{
        require(!userProfiles[msg.sender].isRegistered, "User already registered");

        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });

        emit UserRegistered(msg.sender, _name, block.timestamp); //告诉区块链注册的人和时间  与前面的event声明联系起来
    }

    function updateWeight(uint256 _newWeight) public onlyRegistered{
        UserProfile storage profile = userProfiles[msg.sender];
        
        if (_newWeight < profile.weight && (profile.weight -_newWeight)*100/profile.weight >= 5){
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }

        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    function logWorkout(
        string memory _activityType,
        uint256 _duration,
        uint256 _distance
    ) public onlyRegistered{
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType: _activityType,
            duration: _duration,
            distance:_distance,
            timestamp:block.timestamp
        });  //创建新的锻炼项目记录

        //添加到用户的锻炼历史中
        workoutHistory[msg.sender].push(newWorkout);

        //更新总的状态
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance;

        //向区块链发送事件
        emit WorkoutLogged(
            msg.sender,
            _activityType,
            _duration,
            _distance,
            block.timestamp
        );

        //检查锻炼数里程碑
        if (totalWorkouts[msg.sender] == 10){
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        } else if (totalWorkouts[msg.sender] == 50){
            emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }

        //检查锻炼距离里程碑
        if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000){
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        } //保证了只触发一次里程碑
    }

    function getUserWorkoutCount() public view onlyRegistered returns(uint256){
        return workoutHistory[msg.sender].length;
    }


}
