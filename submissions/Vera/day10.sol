// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleFitnessTracker{
    struct UserProfile{
        string name;
        uint256 weight; // in kg
        bool isRegistered;
    }
    struct WorkoutActivity{
        string activityType;
        uint256 duration; // in minute
        uint256 distance; // in meters
        uint256 timestamp;
    }

    mapping (address => UserProfile) public userProfiles;
    mapping (address => WorkoutActivity[]) private workoutHistory;// only used inside of contract
    mapping (address => uint256) public totalWorkouts;
    mapping (address => uint256) public totalDistance;

    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress,uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(address indexed userAddress, string activityType, uint256 duration, uint256 distance, uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);

    modifier onlyRegistered(){
        require(userProfiles[msg.sender].isRegistered,"User not registered");
        _;
    }

    function stringIsEqual(string memory _s1,string memory _s2)private pure returns (bool){
        return keccak256(bytes(_s1)) == keccak256(bytes(_s2));
    }

    function registerUser(string memory _name,uint256 _weight)external {
        require(!userProfiles[msg.sender].isRegistered,"User already registered");
        require(!stringIsEqual(_name, ""),"parameter _name is a empty string");
        require(_weight>0,"weight should be greater than 0");

        userProfiles[msg.sender] = UserProfile({
            name : _name,
            weight : _weight,
            isRegistered : true
        });
        emit UserRegistered(msg.sender,_name,block.timestamp);
    }

    function updateWeight(uint256 newWeight)external onlyRegistered{
        require(newWeight>0,"weight should be greater than 0");
        UserProfile storage profile = userProfiles[msg.sender];
        // loss weight for about 5%
        if(newWeight*100 <= profile.weight*95) emit MilestoneAchieved(msg.sender,"Weight Goal Reached",block.timestamp);
        profile.weight = newWeight; 
        emit ProfileUpdated(msg.sender,newWeight,block.timestamp);
    }

    function logWorkout(string memory _activityType,uint256 _duration,uint256 _distance)external onlyRegistered{
        require(!stringIsEqual(_activityType, ""),"parameter _activityType is a empty string");
        
        WorkoutActivity memory newWorkoutActivity = WorkoutActivity({
            activityType:_activityType,
            duration:_duration,
            distance:_distance,
            timestamp:block.timestamp
        });

        workoutHistory[msg.sender].push(newWorkoutActivity);
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender]+=_distance;

        emit WorkoutLogged(msg.sender,_activityType,_duration,_distance,block.timestamp);

        if(totalDistance[msg.sender]>= 100000 && totalDistance[msg.sender] - _distance < 100000){
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        }

        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        } else if (totalWorkouts[msg.sender] == 50) {
            emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }
    }

    function getUserWorkoutCount() external view onlyRegistered returns (uint256){
        return (totalWorkouts[msg.sender]);
    }
    
}