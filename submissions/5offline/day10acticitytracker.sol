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
    //这里忘记写[]报错了，不要忘记数据类型

    mapping(address=>uint256 )public totalworkouts;
    mapping (address=> uint256)public totaldistance;
    //建立一些映射来找数据和值,然后开始写入链上日志，供外部监听、查询，日志上而不是blockchain上

    event userRegistered(address indexed userAddress,string name,uint256 timestamp);
    event ProfileUpdated(address indexed userAddress,uint256 newweight, uint256 timstamp);
    event workoutlogged(address indexed userAddress, string activityType, uint256 duration,uint256 distance, uint256 timestamp);
    //注意uint256后面没逗号，timestamp中间没有.

    //和上面的struct内容相同，想记录 struct 的内容，用 struct 的字段展开写进 event：因为不支持嵌套
    event  milestoneachieved(address indexed userAddress,string milstone, uint256 timestamp);

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
          //启用event告诉前端这个人注册好了，msg.sender,用来在事件日志里记录“谁注册了”。

    }
    function updateweight (uint256 _newweight) public onlyregistered{
        userprofile storage profile =userprofiles[msg.sender];
        //因为是永久更新所以用的是storage，/userprofile是profile的变量类型，相当于给=后面的东西起一个昵称
        if (_newweight <profile.weight &&(profile.weight- _newweight)*100/profile.weight>=5){
            //if（条件）{满足条件之后干嘛},if (条件1 && 条件2) {两个条件都为 true 时，这里的代码才会执行
            //profile.weight 是在用结构体时取出体重字段
            emit milestoneachieved(msg.sender, "weight goal reached",block.timestamp);
        }
        profile.weight=_newweight;
        emit ProfileUpdated(msg.sender, _newweight, block.timestamp);}
        
        function logworkout(string memory _activitytype, uint256 _duration, uint256 _distance)public onlyregistered{
            //记录一些开始的新的运动
            workoutactivity memory newworkout = workoutactivity({
                 activityType:_activitytype,
        duration:_duration,
        distance:_distance,
        timestamp:block.timestamp
    });
    //newworkout新变量名字，类型为workoutactivity那个struct，然后给struct里的东西对应值
    workouthistory[msg.sender].push(newworkout);
    //同步到用户历史数据里
    totalworkouts[msg.sender]++;
    totaldistance[msg.sender] +=_distance;
    //记录总量的增加
    emit workoutlogged(msg.sender,_activitytype,_duration,_distance,block.timestamp);
    //同步event

    if (totalworkouts[msg.sender]==10){
        emit milestoneachieved(msg.sender,"10 workouts completed", block.timestamp);


    }
    //if 和else if 从上往下依次检查每个条件。
    //如果一个条件满足，它会执行该条件下的代码块，然后跳过后续所有 else if 和 else。
    //如果条件不满足，就继续检查下一个 else if。
    //这里，if 的大括号 {} 包含的是条件 A 成立时的代码。因为 else if 是跟 if 平级的，不是 if 内部的语句。
    else if (totalworkouts[msg.sender]==50){
        emit milestoneachieved(msg.sender,"50 workouts completed", block.timestamp);
    }
    if (totaldistance[msg.sender]>=100000 && totaldistance[msg.sender]-_distance<100000){
        //总距离到了，但这次输入健身数据之前，和之前的数据进行比较，之前是不是没有到这个数字，只被触发一次
        emit milestoneachieved(msg.sender,"100000 distance completed", block.timestamp);
    }
        }
    function getUserWorkoutCount()public view onlyregistered returns (uint256) {
    return workouthistory[msg.sender].length;}
}
        //计数看这个人进行多少次运动
    
        

