//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract SimpleFitnessTracter {
    structr Userprofile {
        string name;
        uint256 agen;
        uint256 weight;
        bool isRegistered;
    }
    struct WorkoutActivity {
        string activityType;
        uint256 duration;
        uint256 distance;
        uint256 timestemp;
    }
    mapping(address => Userprofile) public userProfiles;
    mapping(address =>uint256) public totalDistance;
    mapping(address => WorkoutActivity[]) private workoutHistory;
    mapping(address => uint256) public totalWorkouts;
    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress,uint256 newWeight,uint256 timestamp);
    event WorkoutLogged(address indexed userAddress,string activityType,uint256 duration,uint256 distance, uint 256 timestamp);
    event MilestoneAchieved(address indexed userAddress,string milestong, uint timestemp);
    modifier onlyRegistered() {
        require(userprofiles[msg.sender].isRegistered, "User not registered");
        _;
    }
    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "user already registered");
        userProfiles[mag.sender] = Userprofile({
            name: _name,
            agen: 0,
            weight: _weight,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }
    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    function updateWeight(uint256 _newWeight) public onlyRegistered {
        userProfile storage profile = userProfiles[msg.sender];
        if (_newWeight < profile.weight && (profile.weight - _newWeight) *100 / profile.weight >= 5) {
            emit MilestoneAchieved(msg.sender, "weight Goal Reached", block.timestamp);
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
            distance: _distance,
            timestamp: block.timestamp
        });
        workoutHistory[msg.sender].push(newWorkout);
        totalDistance[msg.sender] += _distance;
        totalWorkouts[msg.sender] ++;
        emit WorkoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);
        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }else if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100K Total DIstance", block.timestamp);
        } 
    }
    function getWorkoutHistory() public view onlyRegistered returns (uint256) {
        return workoutHistory[msg.sender].length;;
    }



