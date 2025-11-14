//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract SimpleFitnessTracker{
    address public owner;
    //结构体
    //用户数据
    struct userProfile{
        string name;
        uint256 weight;
        bool isRegistered;
    }
    //活动数据,锻炼历史
    struct workoutActivity{
        string activityName;
        uint256 duration;//in seconds
        uint256 distance;//in meters
        uint256 timeStamp;//发生时间
    }
    //映射，将数据与用户关联起来
    mapping(address=>userProfile)public userProfiles;
    //mapping(address=>workoutActivity)private workoutHistory;
    mapping(address => workoutActivity[]) private workoutHistory; 
    //为什么这里要加【】？
    //答：struct 是一组字段的集合（类似一个对象）；数组是多个元素的集合，可以 push。
    //mapping(address => struct) 意味着：每个地址只有一条 struct
    //mapping(address => struct[]) 才意味着：每个地址有一份 “历史记录数组”
    mapping (address=>uint256)public totalWorkouts;//用户总活动次数
    mapping(address=>uint256)public totalDistance;//总活动距离

    //声明事件,注册用户、更新个人信息、记录运动、到达里程碑
    event UserRegistered(
        address indexed userAddress,
        string name,
        uint256 timestamp
    );
    event profileUpdate(
        address indexed userAddress,
        uint256 newWeight,
        uint256 timestamp
    );
    event workoutLogged(
        address indexed userAddress,
        string acticityName,
        uint256 duration,//in seconds
        uint256 distance,//in meters
        uint256 timeStamp//发生时间
    );
    event milestoneAchieved(
        address indexed userAddress,
        string milestone,
        uint256 timestamp
    );

    //修饰符小警察
    modifier onlyRegistered{
        require(userProfiles[msg.sender].isRegistered,"You are not registered");//如果没有注册，则不允许操作
        _;
    }
    //构造函数,初始化主理人？
    constructor (){
       owner=msg.sender;
    }

    //操作开始
    //操作一：注册用户
    function registerUser(string memory _name,uint256 _weight)public{
        //检查用户是否已经注册
        require(userProfiles[msg.sender].isRegistered==false,"You are already registered");

        //如果没有注册就注册一下
        userProfiles[msg.sender]=userProfile({
            name:_name,
            weight:_weight,
            isRegistered:true
        });

        emit UserRegistered(msg.sender, _name, block.timestamp);
        //这行代码告诉区块链：“嘿，有人刚刚注册了——这是他是谁，以及注册的时间。”
    }
    //操作二：更新体重数据，记录进步！追求进步而非完美！可能触发里程碑彩蛋
    function updateWeight(uint256 _newWeight)public onlyRegistered{
        userProfile storage profile=userProfiles[msg.sender];

        //如果阶段性目标达成将触发里程碑事件
        if(_newWeight<profile.weight&&(profile.weight-_newWeight)*100/profile.weight>=5){
            emit milestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }

        profile.weight=_newWeight;//数据更改，在里程碑检查之后，我们继续保存新的体重：
        emit profileUpdate(msg.sender, _newWeight, block.timestamp);//个人信息数据更改
        //提问：这两者数据更改有什么区别？
        //答:后者使得我们让外部世界知道用户的体重已经改变,这有助于前端刷新用户统计数据或重新计算进度条。

    }
    //操作三：记录训练，有可能触发里程碑彩蛋
    function logWorkout(string memory _activityType,uint256 _duration,uint256 _distance)public onlyRegistered{
        //更新一个暂时的活动记录结构体
        workoutActivity memory newWorkout=workoutActivity({
           activityName:_activityType,
           duration:_duration,
            distance:_distance,
            timeStamp:block.timestamp
        });
        workoutHistory[msg.sender].push(newWorkout);//把运动记录添加到历史记录中去
        //统计数据
        totalDistance[msg.sender]+=_distance;
        totalWorkouts[msg.sender]++;
        //触发运动数据记录事件,公布or记录
        emit workoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);
        //检查是否触发运动次数里程碑
        if(totalWorkouts[msg.sender]==10){
            emit milestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        }else if(totalWorkouts[msg.sender]==50){
            emit milestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }
        //检查是否触发距离里程碑
           
        if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit milestoneAchieved(msg.sender, "100K Total Distance",block.timestamp);
        }

    }
    //操作四：统计训练次数
    //设计一个方便的只读函数，告诉用户他们截至目前已经记录了多少次锻炼，非常适合仪表盘或统计数据显示。（接下去可以问gpt，在一个成熟的项目中这个功能通常做哪些应用？）

    function getUserWorkoutCount()public view onlyRegistered returns(uint256){
        return workoutHistory[msg.sender].length;
    }




}