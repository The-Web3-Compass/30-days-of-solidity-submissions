//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FitnessTracker {
    // user information
    struct UserProfile {
        string name;
        uint256 weight; // kg
        bool isRegistered;
    }

    // workout information
    struct WorkoutActivity {
        string activityName;
        uint256 duration; // second
        uint256 distance; // meter
        uint256 calories; // kcal
        uint256 timestamp;
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(address => WorkoutActivity[]) private workoutHistory;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistances;
    mapping(address => uint256) public totalDuration;

    // events that will act like signals our frontend can listen to
    event UserRegistered(address indexed _address, string _name, uint256 timestamp);
    event ProfileUpdated(address indexed _address, uint256 weight, uint256 timestamp);
    event WorkoutLogged(address indexed _address, string activityName, uint256 duration, 
                        uint256 distance, uint256 calories, uint256 timestamp);
    event MilestoneAchieved(address indexed _address, string milestone, uint256 timestamp);

    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "You are not registered");
        _;
    }

    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "You are already registered");

        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    function updateWeight(uint256 newWeight) public onlyRegistered {
        UserProfile storage userProfile = userProfiles[msg.sender];

        if(newWeight < userProfile.weight 
           && (userProfile.weight - newWeight) * 100 / userProfile.weight >= 5) {
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }

        userProfile.weight = newWeight;
        emit ProfileUpdated(msg.sender, newWeight, block.timestamp);
    }

    function logWorkout(
        string memory _activityName, 
        uint256 _duration, 
        uint256 _distance, 
        uint256 _calories) 
        public onlyRegistered {
            // new workout
            WorkoutActivity memory workout = WorkoutActivity({
                activityName: _activityName,
                duration: _duration,
                distance: _distance,
                calories: _calories,
                timestamp: block.timestamp
            });

            // add to workout history et emit event
            workoutHistory[msg.sender].push(workout);
            emit WorkoutLogged(msg.sender, _activityName, _duration, _distance, _calories, block.timestamp);
            
            // update records
            totalDistances[msg.sender] += _distance;
            totalDuration[msg.sender] += _duration;
            totalWorkouts[msg.sender]++;

            // check milestones
            if (_calories >= 500) {
                emit MilestoneAchieved(msg.sender, "Calory Goal Reached", block.timestamp);
            }

            if (totalWorkouts[msg.sender] == 10) {
                emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
            } else if (totalWorkouts[msg.sender] == 50) {
                emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
            }

            if (totalDistances[msg.sender] >= 100000 && (totalDistances[msg.sender] - _distance) < 100000) {
                emit MilestoneAchieved(msg.sender, "100k Total Distance", block.timestamp);
            }

            if (totalDuration[msg.sender] / 3600 >= 100 && (totalDuration[msg.sender] - _duration) / 3600 < 100) {
                emit MilestoneAchieved(msg.sender, "100 Total Hour", block.timestamp);
            }
    }

    function getWorkoutCount(address _address) public view onlyRegistered returns(uint256) {
        return workoutHistory[_address].length;
    }

}