//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

contract activitytracker{
    //目的：记录用户记录，当用户达到某个成就时，提示用户
    //变量：输入items 记录进度 实时更新 设定单位 设计目标 ==把所有的变量思考一下加入list
    //event 是一个宣告性的东西， 链上的“广播公告”系统。
    struct userprofile{
        string name;
        uint256 weight; 
        bool isregistered;

    }
    //struct是把不同类型的变量打包成一个整体，定义成一个东西
    struct workoutactivity{
        string activityType;
        uint256 duration;
        uint256 distance;
        uint256 timestamp;
    }
    mapping(address=>userprofile) public userprofiles;
    mapping(address =>workoutactivity[]) private workouthistory;
    mapping(address=>uint256 )public totalworkouts;
    mapping (address=> uint256)public totaldistance;
    //建立一些映射来找数据和值,然后开始写入链上日志，供外部监听、查询，日志上而不是blockchain上

    event userRegistered(address indexed userAddress,string name,uint256 timestamp);
    event ProfileUpdated(address indexed userAddress,uint256 newweight, uint256 timstamp);
    event workoutlogged(address indexed userAddress, string activitytupe, uint256 duration,uint256 distance, uint256 timestamp);
    //和上面的struct内同相同，想记录 struct 的内容，用 struct 的字段展开写进 event：因为不支持嵌套
    event  milestoneachieved(address indexed userAddress,string milstone, uint256 tomestamp);

    modifier onlyregistered(){
        require (userprofiles[msg.sender].isregistered,"user is not registered.");
        _;
    }
    function registeruser(string memory _name, uint256 _weight) public{
        require (!userprofiles[msg.sender].isregistered, "user is already registered");
        userprofiles[msg.sender]=userprofile({
            name:_name,
            weight:_weight,
            isregistered: true
            //普通变量赋值用 =，struct 命名初始化时字段对值用 :。不要搞混！
            //({}),在调用 struct 类型的“构造器”语法（结构体的实例化表达式).好像是把真实数据塞进去的例子的意思。
             
           
        });
          emit userRegistered(msg.sender, _name, block.timestamp);
          //启用event告诉前端这个人注册好了

    }
    function updateweight(uint256 _newweight) public onlyregistered{
    userprofile storage profile = userprofiles[msg.sender];

    if (_newweight < profile.weight && (profile.weight - _newweight) * 100 / profile.weight >= 5) {
        emit milestoneachieved(msg.sender, "Weight Goal Reached", block.timestamp);
    }

    profile.weight = _newweight;
    emit ProfileUpdated(msg.sender, _newweight, block.timestamp);}

    function logworkout( string memory _activityType, uint256 _duration,uint256 _distance) public onlyregistered{
        workoutactivity memory newworkout = workoutactivity({
            activityType:_activityType,
            duration:_duration,
            distance:_distance,
            timestamp:block.timestamp
        });
       workouthistory[msg.sender].push(newworkout);

        totalworkouts[msg.sender]++;
        totaldistance[msg.sender] += _distance;

        emit workoutlogged(msg.sender, _activityType, _duration, _distance, block.timestamp);

        if(totalworkouts[msg.sender] == 10){
            emit milestoneachieved(msg.sender, "10 workouts completed", block.timestamp);
        }
            else if (totalworkouts[msg.sender] == 50){
            emit milestoneachieved(msg.sender, "50 workouts completed", block.timestamp);
            }

            if(totaldistance[msg.sender] >= 10000 && totaldistance[msg.sender]- _distance <10000){
            emit milestoneachieved(msg.sender, "10K total distance completed", block.timestamp);
            }
    }
    function getUserWorkoutCount() public view onlyregistered returns (uint256) {
    return workouthistory[msg.sender].length;
}

    }