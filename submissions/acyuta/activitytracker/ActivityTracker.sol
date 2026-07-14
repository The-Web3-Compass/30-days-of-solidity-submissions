// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ActivityTracker {
    event UserRegistered(address addr, string user);
    event WorkoutLogged(string name, string workout, uint timestamp);
    event MilestoneReached(address user, string message);
    event ProfileUpdated(address addr, uint weight, uint timestamp);

    struct UserProfile {
        string name;
        uint weight;
    }

    struct Workout {
        string workoutType;
        uint timestamp;
    }

    mapping(address => UserProfile) private users;
    mapping(address => Workout[]) private workoutLog;

    modifier onlyRegistered() {
        require(bytes(users[msg.sender].name).length != 0, "Not registered");
        _;
    }

    function register(string calldata _name, uint _weight) public {
        require(
            bytes(users[msg.sender].name).length == 0,
            "Already registered"
        );

        users[msg.sender] = UserProfile(_name, _weight);
        emit UserRegistered(msg.sender, _name);
    }

    function updateWeight(uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = users[msg.sender];

        if (_newWeight < profile.weight) {
            if (((profile.weight - _newWeight) * 100) / profile.weight >= 5) {
                emit MilestoneReached(msg.sender, "Weight Goal Reached");
            }
        }

        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    function logWorkout(string calldata _workout) public onlyRegistered {
        uint timestamp = block.timestamp;
        workoutLog[msg.sender].push(Workout(_workout, timestamp));

        uint length = workoutLog[msg.sender].length;
        if (length % 10 == 0) {
            emit MilestoneReached(
                msg.sender,
                string(abi.encodePacked(length, " workouts logged!!!"))
            );
        }

        emit WorkoutLogged(users[msg.sender].name, _workout, timestamp);
    }

    function getWorkout(
        uint _index
    ) public view onlyRegistered returns (Workout memory) {
        require(_index < workoutLog[msg.sender].length, "Index out of bounds");
        return workoutLog[msg.sender][_index];
    }
}