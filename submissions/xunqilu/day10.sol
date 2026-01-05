// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ActivityTracker {

    struct UserProfile {
        string name;
        uint256 weight;
        bool isRegistered;
    }

    struct WorkoutActivity {
        string ActivityType;
        uint256 duration;
        uint256 caloriesBurned;
        uint256 timestamp;
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(address => WorkoutActivity[]) private WorkoutActivities;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalCaloriesBurned;
    // firend list
    mapping(address => address[]) public friends;
    // prevent repeating milestone
    mapping(address => mapping(address => bool)) public friendMilestone5Reached;

    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    event WorkoutAdded(address indexed userAddress, string ActivityType, uint256 duration, uint256 caloriesBurned, uint256 timestamp);
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);

    // Friend Type Milestone
    event FriendMilestoneAchieved(address indexed user1, address indexed user2, string milestone, uint256 timestamp);
    event FriendWorkoutTogether(address indexed user1, address indexed user2, string activityType, uint256 timestamp);

    modifier onlyRegistered {
        require(userProfiles[msg.sender].isRegistered, "You are not registered");
        _;
    }

    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "Already registered");
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    function updateWeight(uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = userProfiles[msg.sender];
        if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5) {
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached!!!", block.timestamp);
        }
        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    // Add friends :D
    function addFriend(address _friend) public onlyRegistered {
        require(userProfiles[_friend].isRegistered, "Friend must be registered");
        require(_friend != msg.sender, "Cannot add yourself");
        // check if friend exsit in the list already
        for (uint256 i = 0; i < friends[msg.sender].length; i++) {
            require(friends[msg.sender][i] != _friend, "Already friends");
        }
        friends[msg.sender].push(_friend);
        friends[_friend].push(msg.sender); 
    }

    function logWorkout(string memory _activityType, uint256 _duration, uint256 _calories) public onlyRegistered {
        WorkoutActivity memory newWorkout = WorkoutActivity({
            ActivityType: _activityType,
            duration: _duration,
            caloriesBurned: _calories,
            timestamp: block.timestamp
        });

        WorkoutActivities[msg.sender].push(newWorkout);
        totalWorkouts[msg.sender]++;
        totalCaloriesBurned[msg.sender] += _calories;

        emit WorkoutAdded(msg.sender, _activityType, _duration, _calories, block.timestamp);

        // Check friend type milestones
        address[] memory userFriends = friends[msg.sender];
        for (uint256 i = 0; i < userFriends.length; i++) {
            address friendAddr = userFriends[i];
            if (!userProfiles[friendAddr].isRegistered) continue;
            if (totalWorkouts[msg.sender] >= 5 && totalWorkouts[friendAddr] >= 5 && !friendMilestone5Reached[msg.sender][friendAddr]) {
                friendMilestone5Reached[msg.sender][friendAddr] = true;
                friendMilestone5Reached[friendAddr][msg.sender] = true;
                string memory milestoneMsg = string(
                    abi.encodePacked(
                        "You and ",
                        userProfiles[friendAddr].name,
                        " have both completed 5 workouts!"
                    )
                );
                emit FriendMilestoneAchieved(msg.sender, friendAddr, milestoneMsg, block.timestamp);
            }
        }
    }

    // log a workout which is done with friend
    function logWorkoutWithFriend(
        address _friend,
        string memory _activityType,
        uint256 _duration,
        uint256 _calories
    ) public onlyRegistered {
        require(userProfiles[_friend].isRegistered, "Friend must be registered");
        require(_friend != msg.sender, "Cannot workout with yourself");

        WorkoutActivity memory newWorkout = WorkoutActivity({
            ActivityType: _activityType,
            duration: _duration,
            caloriesBurned: _calories,
            timestamp: block.timestamp
        });

        WorkoutActivities[msg.sender].push(newWorkout);
        WorkoutActivities[_friend].push(newWorkout);

        totalWorkouts[msg.sender]++;
        totalWorkouts[_friend]++;
        totalCaloriesBurned[msg.sender] += _calories;
        totalCaloriesBurned[_friend] += _calories;

        emit WorkoutAdded(msg.sender, _activityType, _duration, _calories, block.timestamp);
        emit WorkoutAdded(_friend, _activityType, _duration, _calories, block.timestamp);
        string memory togetherMsg = string(
            abi.encodePacked(
                "You and ",
                userProfiles[_friend].name,
                " completed ",
                _activityType,
                " together!"
            )
        );

        emit FriendWorkoutTogether(msg.sender, _friend, _activityType, block.timestamp);
        emit FriendMilestoneAchieved(msg.sender, _friend, togetherMsg, block.timestamp);
    }

    function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
        return WorkoutActivities[msg.sender].length;
    }
}
