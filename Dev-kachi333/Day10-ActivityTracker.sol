// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract FitnessTracker{
    struct UserProfie{
        string Name;
        uint256 Weight;
        bool isRegistered;
    }

    struct WorkoutActivity {
        string ActivityType;
        uint256 duration;
        uint256 distance;
        uint256 timestamp;

    }

    mapping (address =>UserProfie) public userProfiles;
    mapping (address=> WorkoutActivity) private workoutHistory;
    mapping (address=>uint256) public totalWorkout;
    mapping (address=>uint256) public  totalDistance;

    event UserRegistered (address indexed userAddress , string name, uint256 timestamp );
    event ProfileUpdated ( address indexed  userAddress , uint256 newWeight , uint256 timestamp);
    event WorkOutLogged (address indexed  userAddress , string activityType , uint256 duration , uint256
    distance , uint256 timestamp);
    event MilestoneAchived ( address indexed  userAddress,  string milestone , uint256 timestamp);

     
modifier onlyRegistered() {
    require(userProfiles[msg.sender].isRegistered, "User not registered");
    _;
}




    //Function to register user
    
function registerUser(string memory _name, uint256 _weight) public {
    require(!userProfiles[msg.sender].isRegistered, "User already registered");

    userProfiles[msg.sender] = UserProfile({
        name: _name,
        weight: _weight,
        isRegistered: true
    });

    emit UserRegistered(msg.sender, _name, block.timestamp);
}   

    //update weight

    function updateWeight(uint256 _newWeight) public onlyRegistered {
    UserProfile storage profile = userProfiles[msg.sender];

    if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5) {
        emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
    }

    profile.weight = _newWeight;
    emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
}

   
function logWorkout(
    string memory _activityType,
    uint256 _duration,
    uint256 _distance
) public onlyRegistered {
    // Create new workout activity
    WorkoutActivity memory newWorkout = WorkoutActivity({
        activityType: _activityType,
        duration: _duration,
        distance: _distance,
        timestamp: block.timestamp
    });

    // Add to user's workout history
    workoutHistory[msg.sender].push(newWorkout);

    // Update total stats
    totalWorkouts[msg.sender]++;
    totalDistance[msg.sender] += _distance;

    // Emit workout logged event
    emit WorkoutLogged(
        msg.sender,
        _activityType,
        _duration,
        _distance,
        block.timestamp
    );

    // Check for workout count milestones
    if (totalWorkouts[msg.sender] == 10) {
        emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
    } else if (totalWorkouts[msg.sender] == 50) {
        emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
    }

    // Check for distance milestones
    if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
        emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
    }
}






                                                       
        




    

}