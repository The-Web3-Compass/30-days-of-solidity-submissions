// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract simpleFitnessTracker{
    address public owner;

    struct userProfile{
        string name;
        uint256 weight;
        bool isRegistered;
    }

    struct workoutActivity{
        string activityType;
        uint256 duration;
        uint256 distance;
        uint256 timestamp;
    }

    mapping (address => userProfile) public userProfiles;
    mapping (address => workoutActivity[]) private workoutHistory;
    mapping (address => uint256) public totalWorkouts;
    mapping (address => uint256) public totalDistance;

    event userRegistered(address indexed userAddress,string name,uint256 timestamp);
    event profileUpdated(address indexed userAddress,uint256 newWeight,uint256 timestamp);
    event workoutLogged(address indexed userAddress,string activityType,uint256 duration,uint256 distance,uint256 timestamp);
    event milestoneAchieved(address indexed userAddress,string milestone,uint256 timestamp);

    constructor(){
        owner = msg.sender;
    }

    modifier onlyRegistered(){
        require(userProfiles[msg.sender].isRegistered,"User not registered.");
        _;
    }

    function registerUser(string memory _name,uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered,"User already registered.");

        userProfiles[msg.sender] = userProfile({
            name:_name,
            weight:_weight,
            isRegistered:true
        });

        emit userRegistered(msg.sender, _name, block.timestamp);
    }

    function updateWeight(uint256 _newWeight) public onlyRegistered{
        userProfile storage profile = userProfiles[msg.sender];

        if(_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5){
            emit milestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }

        profile.weight = _newWeight;

        emit profileUpdated(msg.sender, _newWeight, block.timestamp);
    }

        function logWorkout(string memory _activityType,uint256 _duration,uint256 _distance) public onlyRegistered{
            workoutActivity memory newWorkout = workoutActivity({
                activityType:_activityType,
                duration:_duration,
                distance:_distance,
                timestamp:block.timestamp
            });

            workoutHistory[msg.sender].push(newWorkout);

            totalWorkouts[msg.sender]++;
            totalDistance[msg.sender]+=_distance;

            emit workoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);

            if(totalWorkouts[msg.sender] == 10){
                emit milestoneAchieved(msg.sender, "10 Workouts Completed.", block.timestamp);
            }

            else if(totalWorkouts[msg.sender] == 50){
                emit milestoneAchieved(msg.sender, "50 Workouts Completed.", block.timestamp);
            }

            if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000){
                emit milestoneAchieved(msg.sender, "100k Total Distance.", block.timestamp);
            }
        }

        function getuserWorkoutCount() public view onlyRegistered returns (uint256){
            return workoutHistory[msg.sender].length;
        }
}
