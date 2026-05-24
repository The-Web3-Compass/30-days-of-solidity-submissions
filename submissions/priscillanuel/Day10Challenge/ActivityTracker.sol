// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract ActivityTracker {
    struct UserProfile {
        string name;
        uint256 weight;
        bool isRegistered;
    }

    struct WorkOutActivity {
        string ActivityType;
        uint256 duration;
        uint256 distance;
        uint256 timeStamp;
    }
    mapping(address => UserProfile) public userProfile;
    mapping(address => WorkOutActivity[]) private workOutActivity; // mapping of array of structs)
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistance;

    event UserRegistered(
        address indexed userAddress,
        string name,
        uint256 timestamp
    );

    event profileUpdated(
        address indexed userAddress,
        uint256 newWeight,
        uint256 timeStamp
    );

    event WorkoutLogged(
        address indexed userAddress,
        string ActivityType,
        uint256 duration,
        uint256 distance,
        uint timeStamp
    );

    event mileStoneAcheived(
        address indexed userAddress,
        string milestone,
        uint256 timestamp
    );

    // modifiers
    modifier onlyRegistered() {
        require(userProfile[msg.sender].isRegistered, "you're not registered");
        _;
    }

    //functions

    function registerUsers(string memory _name, uint256 _weight) public {
        require(!userProfile[msg.sender].isRegistered, "user not registered");
        userProfile[msg.sender] = UserProfile({
            name: _name,
            weight: _weight,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    function updateWeight(uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = userProfile[msg.sender];
        if (
            _newWeight < profile.weight &&
            ((profile.weight - _newWeight) * 100) / profile.weight >= 5
        )
            emit mileStoneAcheived(
                msg.sender,
                "weight goal acheived",
                block.timestamp
            );

        profile.weight = _newWeight;

        emit profileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    function logWorkout(
        string memory _activityType,
        uint256 _duration,
        uint256 _distance
    ) public onlyRegistered {
        WorkOutActivity memory newWorkout = WorkOutActivity({
            ActivityType: _activityType,
            duration: _duration,
            distance: _distance,
            timeStamp: block.timestamp
        });

        workOutActivity[msg.sender].push(newWorkout);
        totalDistance[msg.sender] += _distance;
        totalWorkouts[msg.sender]++;

        emit WorkoutLogged(
            msg.sender,
            _activityType,
            _duration,
            _distance,
            block.timestamp
        );

        if (totalWorkouts[msg.sender] == 10) {
            emit mileStoneAcheived(
                msg.sender,
                "weight goal acheived",
                block.timestamp
            );
        } else if (totalWorkouts[msg.sender] == 50) {
            emit mileStoneAcheived(
                msg.sender,
                "50 workout completed",
                block.timestamp
            );
        }

        if (
            totalDistance[msg.sender] >= 100000 &&
            totalDistance[msg.sender] - _distance < 100000
        ) {
            emit mileStoneAcheived(
                msg.sender,
                "100k meters achieved",
                block.timestamp
            );
        } else if (totalWorkouts[msg.sender] >= 500000) {
            emit mileStoneAcheived(
                msg.sender,
                "500k meters achieved",
                block.timestamp
            );
        }
    }
    function getUserWorkoutCount()
        public
        view
        onlyRegistered
        returns (uint256)
    {
        return workOutActivity[msg.sender].length;
    }
}
