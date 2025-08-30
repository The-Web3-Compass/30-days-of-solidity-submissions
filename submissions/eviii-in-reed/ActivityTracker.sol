//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

contract ActivityTracker {
    struct UserProfile {
        string name;
        uint256 weight;
        bool isRegistered;
    }

    struct WorkoutActivities {
        string workoutType;
        uint256 duration;
        uint256 timestamp;
        uint256 distance;
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(address => WorkoutActivities[]) private workoutHistory;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistance;

    // indexed maked a variable searchable
    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(address indexed userAddress, string workoutType, uint256 duration, uint256 distance, uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);

    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "The user is not registered yet!");
        _;
    }

    function registerUser(string memory _name, uint256 _weight) public {
        // check user profile if user is registered
        require(!userProfiles[msg.sender].isRegistered, "The user is already registered!");
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true});
        emit UserRegistered(msg.sender, _name, block.timestamp); 
        // emit triggers the event, wrote into the log and can be picked up by the frontend
        // it is the most gas efficient way to store data on the chain
    }
    function updateWeight(uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = userProfiles[msg.sender]; // a reference named profile comes from storage (not temporary memory)
        if((_newWeight > profile.weight) && ((profile.weight - _newWeight)*100/profile.weight >= 5)) {
            emit MilestoneAchieved(msg.sender, "Weigth goal achieved!", block.timestamp);
        }
        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);

    }

    function logWorkout(string memory _activityType, uint256 _duration, uint256 _distance) public onlyRegistered {
        WorkoutActivities memory newWorkout = WorkoutActivities ({
            workoutType: _activityType,
            duration: _duration, 
            distance: _distance,
            timestamp: block.timestamp
        });

        workoutHistory[msg.sender].push(newWorkout);
        totalWorkouts[msg.sender] ++;
        totalDistance[msg.sender] += _distance;
        emit WorkoutLogged(msg.sender, _activityType,_duration, _distance, block.timestamp);

        if (totalWorkouts[msg.sender]==10) {
            emit MilestoneAchieved(msg.sender, "You have completed 10 woorkouts!", block.timestamp);
        }
        else if (totalWorkouts[msg.sender]==50) {
            emit MilestoneAchieved(msg.sender, "You have completed 50 woorkouts!", block.timestamp);
        }
        if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] -_distance < 1000000) {
            emit MilestoneAchieved(msg.sender, "100k toal distance achieved!", block.timestamp);
        }
    }

    function getUserWorkoutCount() public view onlyRegistered returns(uint256) {
        return workoutHistory[msg.sender].length;
    }
}
