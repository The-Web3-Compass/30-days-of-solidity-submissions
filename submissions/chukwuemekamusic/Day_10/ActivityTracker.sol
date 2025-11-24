// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ActivityTracker {
    error UnAuthorized();
    error UserExistsAlready();
    error WorkoutTypeGoalExists();
    error WorkoutTypeDoesNotExist();

    struct Goal {
        string workoutType; // set only 1 goal per workoutType ?
        uint256 durationSet; // in minutes
        uint256 durationCovered;
        uint256 caloriesBurnt;
        bool isCompleted;
        bool exists;
    }

    struct UserProfile {
        uint256 id;
        string displayName;
        bool isActive;
    }

    uint256 private totalRegisteredUsers;

    mapping (address => mapping(bytes32 workoutType => Goal)) public workoutGoals;
    mapping (address => UserProfile) public userProfiles;
    address private immutable i_owner;

    event WorkoutLogged(
        address indexed user,
        string indexed workoutType, 
        uint256 indexed timestamp,
        uint256 duration, 
        uint256 caloriesBurnt
    );

    event GoalSet (address indexed user, string indexed workoutType, uint256 durationSet);
    event GoalCompleted(
        address indexed user, 
        string indexed workoutType, 
        uint256 caloriesBurnt,
        uint256 timestamp
    );
    event UserRegistered(address indexed user, string indexed displayName);

    modifier onlyOwner {
       require(msg.sender == i_owner); 
       _;
    }

    modifier  onlyRegistered {
        if (!userProfiles[msg.sender].isActive) revert UnAuthorized();
        _;
    }

    modifier checkIfRegistered(address userAddress) {
        if (userProfiles[userAddress].isActive) revert UserExistsAlready();
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    function registerUser(address _userAddress, string memory _displayName) 
    public  onlyOwner checkIfRegistered(_userAddress) {
        userProfiles[_userAddress] = UserProfile({
            id: totalRegisteredUsers++,
            displayName: _displayName, 
            isActive: true
            });
        emit UserRegistered(_userAddress, _displayName);
    
    }

    function selfRegister(string memory _displayName) external {
        if (userProfiles[msg.sender].isActive) revert UserExistsAlready();
        
        userProfiles[msg.sender] = UserProfile({
            id: totalRegisteredUsers++,
            displayName: _displayName,
            isActive: true
        });
        
        emit UserRegistered(msg.sender, _displayName);
    }
 
    function setWorkoutGoal(string memory _workoutType, uint256 _durationSet ) external onlyRegistered {
        bytes32 workoutTypeHash = hashString(_workoutType);
        if (workoutGoals[msg.sender][workoutTypeHash].exists) revert WorkoutTypeGoalExists();

        workoutGoals[msg.sender][workoutTypeHash] = Goal({
            exists : true,
            workoutType: _workoutType, 
            durationSet: _durationSet, 
            isCompleted: false, 
            durationCovered: 0, 
            caloriesBurnt: 0
        });

        emit GoalSet(msg.sender, _workoutType, _durationSet);
    }
    
    function logWorkout(string memory _workoutType , uint256 _duration, uint256 _calories ) external onlyRegistered { 
        bytes32 workoutTypeHash = hashString(_workoutType);
        
        if (!workoutGoals[msg.sender][workoutTypeHash].exists) revert WorkoutTypeDoesNotExist();
        Goal storage userGoal = workoutGoals[msg.sender][workoutTypeHash];
            userGoal.durationCovered += _duration;
            userGoal.caloriesBurnt += _calories;

            if (!userGoal.isCompleted && userGoal.durationCovered >= userGoal.durationSet) { 
                emit GoalCompleted(msg.sender, _workoutType, userGoal.caloriesBurnt, block.timestamp);
            }
        
        emit WorkoutLogged(msg.sender, _workoutType, block.timestamp, _duration, _calories);
    }

    function getWorkoutGoal(address _user, string memory _workoutType) external view returns (Goal memory){
        return workoutGoals[_user][hashString(_workoutType)];
    }

    function hasWorkoutGoal(address _user, string memory _workoutType) 
    external view returns (bool) {
        bytes32 workoutTypeHash = hashString(_workoutType);
        return workoutGoals[_user][workoutTypeHash].exists;
    }

    function hashString(string memory _word) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_word));
    }
    
}