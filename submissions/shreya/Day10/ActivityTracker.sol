// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ActivityTracker{
    struct UserProfile{
        string name;
        uint256 weight;
        bool isRegistered;
    }
    struct WorkoutActivity{
        string ActivityType;
        uint256 d;
        uint256 dist;
        uint256 ts;
    }
    mapping(address => UserProfile) public userProfiles;
    mapping(address => WorkoutActivity[]) private WorkoutActivities;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistance;

    event UserRegistered(address indexed userAdd, string name , uint256 ts);
    event ProfileUpload(address indexed userAdd, uint256 newWeight, uint256 ts);
    event WorkoutLogged(address indexed userAdd, string ActivityType, uint256 d, uint256 dist, uint256 ts);
    event MilestoneAcheived(address indexed userAdd, string milestone , uint256 ts);

    modifier onlyRegistered{
        require(userProfiles[msg.sender].isRegistered,"User is Registered");
        _;
    }
    function regUser(string memory _name,uint256 _weight) public{
        require(userProfiles[msg.sender].isRegistered,"User is alr registered");
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }
    function updateWeight(uint256 _newWeight) public onlyRegistered{
        UserProfile storage profile = userProfiles[msg.sender];
        if(_newWeight < profile.weight && (profile.weight - _newWeight)* 100/ profile.weight >= 5){
            emit MilestoneAcheived(msg.sender, "Weight Goal Reached", block.timestamp);
        }
        profile.weight = _newWeight;
        emit ProfileUpload(msg.sender, _newWeight, block.timestamp);
    }
    function logWorkout(string memory _activityType, uint256 _d, uint256 _dist) public onlyRegistered{
        WorkoutActivity memory newWorkout = WorkoutActivity({
            ActivityType: _activityType,
            d: _d,
            dist: _dist,
            ts: block.timestamp
        });

        WorkoutActivities[msg.sender].push(newWorkout);
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _d;
        emit WorkoutLogged(msg.sender,_activityType,_d, _dist, block.timestamp);

        // check milestones 
        if(totalWorkouts[msg.sender] == 10){
            emit MilestoneAcheived(msg.sender,"10 unit Achieved",block.timestamp);
        }
        else if(totalWorkouts[msg.sender] == 40){
            emit MilestoneAcheived(msg.sender,"40 unit Achieved",block.timestamp);
        }
        if(totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _dist < 100000){
            emit MilestoneAcheived(msg.sender, "100K Total distance",block.timestamp);
        }
    }
    function getUserWorkCount() public view onlyRegistered returns (uint256){
        return WorkoutActivities[msg.sender].length;
    }
}