// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

/**
 * @title ActivityTracker
 * @author Eric (https://github.com/0xxEric)
 * @notice A ActivityTracker that track exercise .
 * @custom:project 30-days-of-solidity-submissions: Day10
 */

contract ActivityTracker {
    address public admin;
    address[] public userAddresses;

    Workout[] public workoutList;


    mapping(address=>UserWorkout) public workoutRecords;

    enum ExerciseType {
        Running,    // 0
        Strength,     // 1  
        Yoga,   // 2
        Swimming  // 3
    }

    struct Workout{
        ExerciseType etype;
        uint32 duration;
        uint32 calories;

    }

    struct UserWorkout{
        address user;
        Workout[] workouts;
        uint32 totalWorkouts;
        uint32 totalDuration;
        uint32 totalCalories;
        mapping(ExerciseType=>uint32) typeCount;
    }

    event UserRegistered(address indexed user);
    event WorkoutRecord(address indexed user,ExerciseType etype,uint32 duration,uint32 calories);
    event TenWorkoutsReached( address indexed user); //when reached 10 times workout;
    event FivehundredReached(address indexed user); //when reached 500 minutes ;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    constructor() {
        admin = msg.sender;
    }

        function logWorkout(
        ExerciseType _type,
        uint32 _duration,
        uint32 _calories
    ) external {
        require(_duration > 0, "Duration must be positive");
        require(_calories > 0, "Calories must be positive");
        
        UserWorkout storage record = workoutRecords[msg.sender];

        // if new user，init record
        if (record.user == address(0)) {
            record.user = msg.sender;
            userAddresses.push(msg.sender);
            emit UserRegistered(msg.sender);
        }

        Workout memory newWorkout = Workout({
            etype: _type,
            duration: _duration,
            calories: _calories
        });
         // add to record
        record.workouts.push(newWorkout);
        record.totalWorkouts++;
        record.totalDuration += _duration;
        record.totalCalories += _calories;
        record.typeCount[_type]++;
        emit WorkoutRecord(msg.sender,_type,_duration,_calories);

        if (record.totalWorkouts>=10)
        {
            emit TenWorkoutsReached(msg.sender);
        }
        if (record.totalDuration>=500)
        {
            emit FivehundredReached(msg.sender);
        }
    }

        function getUserWorkout(address user ) public view returns (uint32 totalWorkouts,uint32 totalDuration, uint32 totalCalories){
            require(user!=address(0), "empty address");
            UserWorkout storage uworkout = workoutRecords[user];
            return (uworkout.totalWorkouts,uworkout.totalDuration,uworkout.totalCalories);
        }

}
