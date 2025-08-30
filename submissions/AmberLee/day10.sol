// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleFitnessTracker{

    mapping(address=>UserProfile) public UserProfile;

    struct UserProfile{
        string name;
        uint256 weight;
        bool isRegistered;
    }

    struct WorkoutActivity{
        string activityType;
        uint256 duration;
        uint256 distance;
        uint timestamp;
    }
    
    function registerUser (string memory _name, uint256 _weight) public {
        require(!userProfile[msg.sender].isRegistered, "User already registered");
        
        userProfile [msg.sender] = Userprofile ({
            name :_name,
            weight: _weight,
            isRegistered: true
        });

        emit UserRegistered (msg.sender, _name, _weight);
    }
        event UserRegistered(address indexed userAddress, string name, uint256 timestamp);

    function updateWeight (uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = userProfiles [msg.sender];

        if (_newWeight < profile.weight && (profile.weight - _newWeight <= 10)){
            emit MilestoneAchieved (msg.sender, "Weight Goal Reached", block.timestamp);
        }
        profile.weight =_newWeight;

        emit ProfileUpdated (msg.sender, _newWeight, block.timestamp);
    }
    
    function logWorkout(
        string memory _activityType,
        uint256 _duration,
        uint256 _distance
    ) public onlyRegistered {
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activity:_activityType,
            duration :_duration,
            distance :_distance,
            timestamp: block.timestamp
        });

        workoutHistory [msg.sender]. push (newWorkout);

        totalWorkout [msg.sender]++;
        totalDistance [msg.sender] += _distance;
        emit WorkoutLogged( msg.sender, newWorkout );

        if (totalWorkouts[msg.sender] == 10) {
            emit GoalReached(msg.sender);  }
        if (totalDistance [msg.sender] >= 10000 && totalDistance [msg.sender]- _distance < 100000){
            emit MilestoneAchieved (msg.sender,"100k Total Distance", block. timestamp);
        }
    }
        function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
        return workoutHistory[msg.sender].length;}
    
}