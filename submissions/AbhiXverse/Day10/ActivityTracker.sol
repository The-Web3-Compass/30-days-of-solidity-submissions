// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

contract ActivityTracker {

    struct UserProfile {
        string name;
        uint256 weight;
        bool isRegistered;
    }

    struct WorkoutActivity {
        string ActivityType;
        uint256 duration;  // in sec's
        uint256 distance;
        uint256 timestamp;
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(address => WorkoutActivity[]) private workoutActivities;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistance;

    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(address indexed userAddress, string ActivityType, uint256 duration, uint256 distance, uint256 timestamp);
    event MilestoneAchieved(address indexed userAdress, string milestone, uint256 timestamp);


    modifier onlyRegistered()  {
        require(userProfiles[msg.sender].isRegistered, "User is not registered");
        _;
    }

    function register(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered," User is already registered");
        userProfiles[msg.sender] = UserProfile ({
            name: _name,
            weight: _weight,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }


    function updateWeight(uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = userProfiles[msg.sender];
        if (_newWeight < profile.weight && (profile.weight - _newWeight)*100/profile.weight >= 5) {
            emit MilestoneAchieved(msg.sender, "Weight goal reached", block.timestamp);
        }
        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);

    }

    function logWorkout (string memory _activityType, uint256 _duration, uint256 _distance) public onlyRegistered {
        WorkoutActivity memory newWorkout = WorkoutActivity ({
            ActivityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });
        workoutActivities[msg.sender].push(newWorkout);
        totalWorkouts[msg.sender]++;
        totalDistance[msg.sender] += _distance;
        emit WorkoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);

        if(totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "10 workout completed", block.timestamp);
        }
        else if(totalWorkouts[msg.sender] == 50) {
            emit MilestoneAchieved(msg.sender, "50 workout completed", block.timestamp);
        }

        if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100,000 total distance", block.timestamp);
        }
    }


    function getUserWorkoutCount() public view returns (uint256) {
            return workoutActivities[msg.sender].length;
        }

}



