// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleFitnessTracker {
    struct Workout {
        string workoutType;
        uint256 durationMinutes;
        uint256 calories;
        uint256 distanceKm;
        uint256 timestamp;
    }

    struct UserProfile {
        string name;
        uint256 heightCm;
        uint256 weightKg;
        uint256 totalWorkouts;
        uint256 totalMinutes;
        uint256 totalCalories;
        uint256 totalDistanceKm;
        Workout[] history;
        mapping(string => bool) achievementsUnlocked;
    }

    mapping(address => UserProfile) private users;

    event WorkoutLogged(
        address indexed user,
        string workoutType,
        uint256 durationMinutes,
        uint256 calories,
        uint256 distanceKm,
        uint256 timestamp
    );

    event MilestoneAchieved(
        address indexed user,
        string milestoneType,
        uint256 value
    );

    function registerUser(string memory _name, uint256 _heightCm, uint256 _weightKg) public {
        UserProfile storage user = users[msg.sender];
        require(bytes(user.name).length == 0, "User already registered");
        user.name = _name;
        user.heightCm = _heightCm;
        user.weightKg = _weightKg;
    }

    function logWorkout(string memory _type, uint256 _duration, uint256 _calories, uint256 _distanceKm) public {
        UserProfile storage user = users[msg.sender];
        require(bytes(user.name).length > 0, "User not registered");

        Workout memory newWorkout = Workout({
            workoutType: _type,
            durationMinutes: _duration,
            calories: _calories,
            distanceKm: _distanceKm,
            timestamp: block.timestamp
        });

        user.history.push(newWorkout);
        user.totalWorkouts++;
        user.totalMinutes += _duration;
        user.totalCalories += _calories;
        user.totalDistanceKm += _distanceKm;

        emit WorkoutLogged(msg.sender, _type, _duration, _calories, _distanceKm, block.timestamp);

        _checkMilestones(msg.sender);
    }

    function _checkMilestones(address _user) internal {
        UserProfile storage user = users[_user];

        if (!user.achievementsUnlocked["10 Workouts"] && user.totalWorkouts >= 10) {
            user.achievementsUnlocked["10 Workouts"] = true;
            emit MilestoneAchieved(_user, "10 Workouts", 10);
        }

        if (!user.achievementsUnlocked["500 Minutes"] && user.totalMinutes >= 500) {
            user.achievementsUnlocked["500 Minutes"] = true;
            emit MilestoneAchieved(_user, "500 Minutes", user.totalMinutes);
        }

        if (!user.achievementsUnlocked["1000 Calories"] && user.totalCalories >= 1000) {
            user.achievementsUnlocked["1000 Calories"] = true;
            emit MilestoneAchieved(_user, "1000 Calories", user.totalCalories);
        }

        if (!user.achievementsUnlocked["100 KM"] && user.totalDistanceKm >= 100) {
            user.achievementsUnlocked["100 KM"] = true;
            emit MilestoneAchieved(_user, "100 KM", user.totalDistanceKm);
        }

        if (!user.achievementsUnlocked["Marathon Distance"] && user.totalDistanceKm >= 42) {
            user.achievementsUnlocked["Marathon Distance"] = true;
            emit MilestoneAchieved(_user, "Marathon Distance", user.totalDistanceKm);
        }
    }

    function getWorkoutHistory(address _user) public view returns (Workout[] memory) {
        return users[_user].history;
    }

    function getUserProfile(address _user) public view returns (
        string memory,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) {
        UserProfile storage user = users[_user];
        return (
            user.name,
            user.heightCm,
            user.weightKg,
            user.totalWorkouts,
            user.totalMinutes,
            user.totalCalories,
            user.totalDistanceKm
        );
    }

    function hasAchieved(address _user, string memory _milestone) public view returns (bool) {
        return users[_user].achievementsUnlocked[_milestone];
    }
}
