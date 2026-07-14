// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error NotOwner();
error InvalidValue();

contract ActivityTracker {
    address public owner;
    uint256 public minutesMilestone = 500;
    uint256 public sessionsBatch = 10;

    struct Workout {
        string wtype;
        uint256 mins;
        uint256 calories;
        uint256 timestamp;
    }

    mapping(address => Workout[]) public logs;
    mapping(address => uint256) public totalMinutes;
    mapping(address => uint256) public totalSessions;
    mapping(address => bool) public minutesMilestoneHit;

    event WorkoutLogged(address indexed user, string wtype, uint256 mins, uint256 calories);
    event MilestoneReached(address indexed user, string milestone, uint256 value);

    constructor() { owner = msg.sender; }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function setMilestones(uint256 _minutes, uint256 _batch) external onlyOwner {
        if (_minutes == 0 || _batch == 0) revert InvalidValue();
        minutesMilestone = _minutes;
        sessionsBatch = _batch;
    }

    function logWorkout(string calldata wtype, uint256 mins, uint256 calories) external {
        if (mins == 0) revert InvalidValue();
        logs[msg.sender].push(Workout(wtype, mins, calories, block.timestamp));
        totalMinutes[msg.sender] += mins;
        totalSessions[msg.sender] += 1;
        emit WorkoutLogged(msg.sender, wtype, mins, calories);
        if (!minutesMilestoneHit[msg.sender] && totalMinutes[msg.sender] >= minutesMilestone) {
            minutesMilestoneHit[msg.sender] = true;
            emit MilestoneReached(msg.sender, "TOTAL_MINUTES", totalMinutes[msg.sender]);
        }
        if (totalSessions[msg.sender] % sessionsBatch == 0) {
            emit MilestoneReached(msg.sender, "SESSIONS", totalSessions[msg.sender]);
        }
    }
}