// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title ActivityTracker
 * @dev Create a smart contract that logs user workouts and emits events when fitness goals are reached —
 * like 10 workouts in a week or 500 total minutes.
 * Users log each session (type, duration, calories), and the contract tracks progress.
 * Events use *indexed* parameters to make it easy for frontends or off-chain tools to filter logs by user and milestone —
 * just like a backend for a decentralized fitness tracker with achievement unlocks.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 10
 */
contract ActivityTracker {
    struct Activity {
        string category;
        uint16 duration;
        uint16 distance;
        uint256 timestamp;
    }

    event ActivityLog(address indexed member, string indexed category, uint16 duration, uint16 distance);

    event MilestoneLog(address indexed member, string indexed category, uint256 number);

    address public manager;
    mapping(address => bool) public members;
    mapping(address => Activity[]) public activities;
    mapping(address => uint256) public totalDistances;
    mapping(address => uint256) public totalDurations;

    constructor() {
        manager = msg.sender;
        members[manager] = true;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "only manager is allowed to perform this action");
        _;
    }

    modifier onlyMember(address a) {
        require(members[a], "only a member is allowed to perform or be party to this action");
        _;
    }

    function addMember(address member) public onlyManager {
        members[member] = true;
    }

    function removeMember(address member) public onlyManager {
        members[member] = false;
    }

    function log(string memory category, uint16 duration, uint16 distance) public onlyMember(msg.sender) {
        Activity memory activity = Activity({
            category: category,
            duration: duration,
            distance: distance,
            timestamp: block.timestamp
        });

        //current values
        uint256 numActivities = activities[msg.sender].length;
        uint256 totalDistance = totalDistances[msg.sender];
        uint256 totalDuration = totalDurations[msg.sender];

        // update values
        activities[msg.sender].push(activity);
        totalDistances[msg.sender] += distance;
        totalDurations[msg.sender] += duration;

        emit ActivityLog(msg.sender, category, duration, distance);

        // check if milestones have been hit
        if ((numActivities >> 2) < (activities[msg.sender].length >> 2)) {
            emit MilestoneLog(msg.sender, "Activities", activities[msg.sender].length);
        }
        if ((totalDistance >> 2) < (totalDistances[msg.sender] >> 2)) {
            emit MilestoneLog(msg.sender, "Distance", totalDistances[msg.sender]);
        }
        if ((totalDuration >> 2) < (totalDurations[msg.sender] >> 2)) {
            emit MilestoneLog(msg.sender, "Duration", totalDistances[msg.sender]);
        }
    }
}
