//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract ActivityTracker{

    struct UserProfile {
        string name;
        uint256 weight;
        bool isRegistered;

    }

    struct WorkoutActivity {
        string ActivityType;
        uint256 duration;
        uint256 distance;
        uint256 timestamp;

    }

    mapping (address => UserProfile) public userprofiles;
    mapping (address => WorkoutActivity[]) private workoutactivities;
    mapping (address => uint256) public totalworkouts;
    mapping (address => uint256) public totaldistance;

    event UserRegistered(address indexed UserAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed UserAddress, uint256 newweight, uint256 timestamp);
    event WorkoutLogged(address indexed UserAddress, string ActivityType, uint256 duration, uint256 timestamp);
    event MilestoneAchieved(address indexed UserAddress, string milestone, uint256 timestamp);

    modifier OnlyRegistered{
        require(userprofiles[msg.sender].isRegistered, "User is not registered");
        _;

    }

    function RegisterUser(string memory _name_, uint256 _weight_) public {
        require(!userprofiles[msg.sender].isRegistered, "User is already registered");
        userprofiles[msg.sender] = UserProfile({
            name: _name_,
            weight: _weight_,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, _name_, block.timestamp);

    }

    function UpdateWeight(uint256 _newweight_) public OnlyRegistered{
        UserProfile storage profile = userprofiles[msg.sender];
        if(_newweight_ < profile.weight && (profile.weight - _newweight_)*100/profile.weight >=5){
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }
        profile.weight = _newweight_;
        emit ProfileUpdated(msg.sender, _newweight_, block.timestamp);

    }

    function LogWorkout(string memory _activitytype_, uint256 _duration_, uint256 _distance_) public OnlyRegistered{
        WorkoutActivity memory newworkout = WorkoutActivity({
            ActivityType: _activitytype_,
            duration: _duration_,
            distance:_distance_,
            timestamp: block.timestamp
        });

        workoutactivities[msg.sender].push(newworkout);
        totalworkouts[msg.sender]++;
        totaldistance[msg.sender] += _distance_;
        emit WorkoutLogged(msg.sender, _activitytype_, _duration_, block.timestamp);

        if(totalworkouts[msg.sender] == 10){
            emit MilestoneAchieved(msg.sender, "10 Workout completed", block.timestamp);
        }
        else if(totalworkouts[msg.sender] == 50){
            emit MilestoneAchieved(msg.sender, "50 Workout completed", block.timestamp);
        }
        if(totaldistance[msg.sender] >=100000 && totaldistance[msg.sender] - _distance_ <100000){
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        }

    }

    function GetUserWorkoutCount() public view OnlyRegistered returns(uint256){
        return workoutactivities[msg.sender].length;
        
    }

}
