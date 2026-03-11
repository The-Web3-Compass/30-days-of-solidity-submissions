// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ActivityTracker {

    // Event to log activities
    event ActivityLogged(address indexed user, string activity, uint timestamp);

    // Store number of activities per user
    mapping(address => uint) public activityCount;

    // Function to log an activity
    function logActivity(string memory _activity) public {

        activityCount[msg.sender] += 1;

        // Emit event
        emit ActivityLogged(msg.sender, _activity, block.timestamp);
    }

    // Get total activities of a user
    function getActivityCount(address _user) public view returns (uint) {
        return activityCount[_user];
    }
}