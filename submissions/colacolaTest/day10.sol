//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SimpleFitnessTracker{

    address public owner;

    struct UsersProfile{string name; uint256 weight; bool registered;}
    struct WorkoutActivity{string activityType; uint256 duration; uint256 distance; uint256 timestamp;}
    
    mapping(address => UsersProfile) public userProfiles;
    mapping(address => WorkoutActivity[]) public workoutHistory;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistance;

    event UserRegistered(address indexed userAddress, string indexed name, uint timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint timestamp);
    event WorkoutLogged(address indexed userAddress,string activityType, uint duration, uint distance, uint timestamp);
    event MilestoneAchieved(address indexed userAddress, string milestone, uint timestamp);

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "Only owner can do this action.");
        _;
    }

    modifier onlyRegistered() {
        require(userProfiles[msg.sender].registered, "User not registered.");
        _;
    }

    function registerUser(string memory _name, uint _weight) public {
        require(!userProfiles[msg.sender].registered, "User has been registered.");
        userProfiles[msg.sender] = UsersProfile({
            name: _name, weight: _weight, registered: true
            });

        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    function updateWeight(uint _newWeight) public onlyRegistered {       
        if( _newWeight < userProfiles[msg.sender].weight &&(userProfiles[msg.sender].weight - _newWeight) * 100 /userProfiles[msg.sender].weight >=5){
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }

        userProfiles[msg.sender].weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    function logWorkout(string memory _activityType, uint256 _duration, uint256 _distance) public onlyRegistered {
        WorkoutActivity memory newWorkout = WorkoutActivity(_activityType, _duration, _distance, block.timestamp);
        workoutHistory[msg.sender].push(newWorkout);
        totalWorkouts[msg.sender] ++;
        totalDistance[msg.sender] += _distance;

        emit WorkoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);

        if(totalWorkouts[msg.sender]%10 == 0){
            emit MilestoneAchieved(msg.sender, "Workouts Goal Reached", block.timestamp);           
        } 

        if(totalDistance[msg.sender]%10000 == 0){
            emit MilestoneAchieved(msg.sender, "Distance Goal Reached", block.timestamp);
        }
    }

        function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
            return workoutHistory[msg.sender].length;
        }
}
