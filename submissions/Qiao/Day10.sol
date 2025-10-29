//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FitnessTracker {
    address public owner;
    
    struct User {
        string name;
        uint256 weight; 
        bool isRegistered;
        Activity[] activities;
        uint256 totalWorkouts;
        uint256 totalDistance;
        uint256 totalDuration;
    }    
    
    struct Activity {
        string activityType; 
        uint256 duration;    // in seconds
        uint256 distance;    // in meters
        uint256 logTime;   
    }
   
    mapping(address => User) public users;

    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    event ActivityLogged(
        address indexed userAddress, 
        string activityType, 
        uint256 duration, 
        uint256 distance, 
        uint256 timestamp
    );
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);
    

    modifier onlyRegisteredUser {
        require(users[msg.sender].isRegistered, "Only a registered user can perform this action.");
        _;
    }

    constructor () {
        owner = msg.sender;
    }

    function register (address _address, string memory _name, uint256 _weight) external {
        User storage user = users[_address];
        user.name = _name;
        user.weight = _weight;
        user.isRegistered = true;

        emit UserRegistered(_address, _name, block.timestamp);
    }

    function logActivity (address _address, string memory _type, uint256 _duration, uint256 _distance) 
        external onlyRegisteredUser{
        Activity memory activity = Activity(_type,_duration,_distance,block.timestamp);
        users[_address].activities.push(activity);
        users[_address].totalDuration += _duration;
        users[_address].totalDistance += _distance;
        users[_address].totalWorkouts += 1;

        emit ActivityLogged(_address, _type, _duration, _distance, block.timestamp);
    }

    function updateWeight(uint256 _weight) public onlyRegisteredUser {
        User storage user = users[msg.sender];
        
        if (_weight < user.weight && (user.weight - _weight) * 100 / user.weight >= 5) {
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }
        
        user.weight = _weight;
        
        emit ProfileUpdated(msg.sender, _weight, block.timestamp);
    }
    
}
