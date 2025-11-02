//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract ActivityTracker{

    //结构体
    struct UserProfile{
        string name;
        uint256 weight;
        bool isRegistered;
    }

    struct WorkoutActivity{
        string workoutType;
        uint256 duration;
        uint256 distance;
        uint256 timestamp;
    }

    //映射
    mapping(address => UserProfile) public userProfiles;
    mapping(address => WorkoutActivity[]) private workout;   //指向结构体
    mapping(address => uint256) public totalTimes;   //每个用户锻炼总次数
    mapping(address => uint256) public totalDistance;   //每个用户锻炼总距离

    //事件
    event UserRegistered(address indexed userAdr,string name,uint256 timestamp);
    event ProfileUpdated(address indexed userAdr,uint256 weight,uint256 timestamp);
    event WorkoutLogged(address indexed userAdr,string activityType,uint256 duration, uint256 distance,uint256 timestamp);
    event MilestoneAchieved(address indexed userAdr,string achievement,uint256 timestamp);

    modifier onlyRegister(){
        require(userProfiles[msg.sender].isRegistered,"Access Denied!");
        _;

    }

    //注册
    function register(string memory _name,uint256 _weight) public{
        userProfiles[msg.sender] = UserProfile({name: _name,weight: _weight,isRegistered: true});
        //触发事件
        emit UserRegistered(msg.sender,_name,block.timestamp);
    }

    //更新体重
    function updateWeight(uint256 _weight) public onlyRegister {
        //storage确保更新是永久的，并反映在userProfiles 映射中
        UserProfile storage userProfile = userProfiles[msg.sender];
        //如果体重减少了5%，完成体重目标
        if (_weight < userProfile.weight && _weight * 100 <= userProfile.weight * 95) {
        emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);}
        userProfile.weight = _weight;
        emit ProfileUpdated(msg.sender, _weight, block.timestamp);
    }

    //锻炼记录
    function logWorkout(string memory _workoutType,uint256 _duration,uint256 _distance) public onlyRegister{
        //创建新的结构体实例  由于创建是为了直接加入数组中 所以使用了memory 节省空间
        WorkoutActivity memory newWorkout = WorkoutActivity({workoutType: _workoutType,duration: _duration,distance: _distance,timestamp: block.timestamp});
        workout[msg.sender].push(newWorkout);
        totalDistance[msg.sender] += _distance;
        totalTimes[msg.sender]++;
        emit WorkoutLogged(msg.sender,_workoutType,_duration,_distance,block.timestamp);

    //分别在锻炼次数达到10和50次以及锻炼距离达到100K时达成成就
         if (totalTimes[msg.sender] == 10) {
        emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);} 
        else if (totalTimes[msg.sender] == 50) {
        emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);}

        //注意大括号的位置！！！  通过将新的总距离减去这一次的总距离判断是否为第一次达到100000
         if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000){
        emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);}
     
    }

    //返回用户锻炼总次数
    function getUserWorkoutCount() public view returns (uint256){
        return workout[msg.sender].length;
    }



}