// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ActivityTracker {
    struct UserProfile {
        string name;
        uint256 weight;
        bool isRegistered;
    }

    struct WorkoutActivity {
        string activityType;
        uint256 duration;
        uint256 distance;
        uint256 timestamp;
    }

    mapping(address => UserProfile) public UserProfiles;
    mapping(address => WorkoutActivity[]) public WorkoutHistory;
    mapping(address => uint256) public TotalDistance; 

    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 weight, uint256 timestamp);
    event WorkoutLogged(address indexed userAddress, string activityType, uint256 duration, uint256 distance, uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);

    modifier onlyRegistered {
        require(UserProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    function registerUser(string memory _name, uint256 _weight) public {
        require(!UserProfiles[msg.sender].isRegistered, "Already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(_weight > 0, "Weight must be positive");

        UserProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    function updateWeight(uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = UserProfiles[msg.sender];
        require(_newWeight > 0, "Weight must be positive");

        if (_newWeight < profile.weight && (profile.weight - _newWeight) * 1000 >= profile.weight * 50) {
            emit MilestoneAchieved(msg.sender, "Weight loss of 5% achieved!", block.timestamp);
        }
        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    function logWorkout(
        string memory _activityType,
        uint256 _duration,
        uint256 _distance
    ) public onlyRegistered {
        require(bytes(_activityType).length > 0, "Activity type cannot be empty");
        require(_duration > 0, "Duration must be positive");
        require(_distance > 0, "Distance must be positive");

        WorkoutActivity[] storage history = WorkoutHistory[msg.sender];
        history.push(WorkoutActivity({
            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        }));

        uint256 workoutCount = history.length;
        if (workoutCount == 10) {
            emit MilestoneAchieved(msg.sender, "10 workouts completed!", block.timestamp);
        } else if (workoutCount == 50) {
            emit MilestoneAchieved(msg.sender, "50 workouts completed!", block.timestamp);
        }

        uint256 newTotalDistance = TotalDistance[msg.sender] + _distance;
        if (newTotalDistance >= 100000 && TotalDistance[msg.sender] < 100000) {
            emit MilestoneAchieved(msg.sender, "100K total distance covered!", block.timestamp);
        }
        unchecked { TotalDistance[msg.sender] = newTotalDistance; }
    }

    function getUserWorkoutCount() public onlyRegistered view returns (uint256) {
        return WorkoutHistory[msg.sender].length;
    }
}