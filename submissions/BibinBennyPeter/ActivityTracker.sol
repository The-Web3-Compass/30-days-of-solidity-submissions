// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ActivityTracker {
    
    mapping(address => uint256) public duration;
    mapping(address => uint256) public calories;

    event ActivityAdded(address indexed user, string activityType, uint256 duration, uint256 calories);
    event MilestoneUpdate(string milestoneType, string message);

    function logActivity(uint256 memory _duration, uint256 memory _calories) public {
        require(_duration > 0, "Duration must be greater than zero");
        require(_calories > 0, "Calories must be greater than zero");

        duration[msg.sender] += _duration;
        calories[msg.sender] += _calories;

        emit ActivityAdded(msg.sender, _type, _duration, _calories);

        durationMilestones(duration[msg.sender]);
        caloriesMilestones(calories[msg.sender]);
    }

    function durationMilestones(uint256 _duration) public returns (string memory) {
        if (_duration >= 60000) {
            emit MilestoneUpdate("Marathoner", "Sarge you're a true marathoner!");
        } else if (_duration >= 45000) {
            emit MilestoneUpdate("Ultra Runner", "Sarge you're an ultra runner!");
        } else if (_duration >= 36000) {
            emit MilestoneUpdate("Athlete", "Sarge you're an athlete!");
        } else if (_duration >= 30000) {
            emit MilestoneUpdate("Runner", "Sarge you're a runner!");
        }else if (_duration >= 30000) {
            emit MilestoneUpdate("Runner", "Sarge you're a runner!");
        } else if (_duration >= 15000) {
            emit MilestoneUpdate("Jogger", "Sarge you're a jogger!");
        } else {
            return "Keep going, Sarge!";
        }
    }

    function caloriesMilestones(uint256 _calories) public returns (string memory) {
        if (_calories >= 100000) {
            emit MilestoneUpdate("Astro","Sarge you're out of this world!");
        } else if (_caloroies >= 75000) {
            emit MilestoneUpdate("Superhero","Sarge you're a superhero!");
        } else if (_calories >= 50000) {
            emit MilestoneUpdate("Champion","Sarge you're a champion!");
        } else if (_calories >= 10000) {
            emit MilestoneUpdate("Hero","Sarge you're a hero!");
        } else if (_calori00es >= 1000) {
            emit MilestoneUpdate("Warrior","Sarge you're a warrior!");
        } else {
            return "Keep pushing, Sarge!";
        }
    }


};
