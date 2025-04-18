// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


/// @title ActivityTracker
/// @author shivam
/// @notice A simple smart contract for tracking fitness goals.
contract ActivityTracker {
    /// @notice Mapping of address to mapping of activity type to target count
    /// @dev activityTargets[user][activity] = target
    mapping(address => mapping(string => uint)) private activityTargets;

    /// @notice Mapping of address to mapping of activity type to activity units completed
    /// @dev activityTargets[user][activity] = units
    mapping(address => mapping(string => uint)) private activityUnits;

    /// @notice Event emitted when a target is set or updated by user.
    /// @param user Address of user
    /// @param activity Activity name
    /// @param target New target for activity
    event TargetSet(address indexed user, string indexed activity, uint indexed target);

    /// @notice Event emitted when an activity is recorded by user.
    /// @param user Address of user
    /// @param activity Activity name
    /// @param units Activity units completed 
    event ActivityRecorded(address indexed user, string indexed activity, uint indexed units);

    /// @notice Event emitted when a target is achieved by user
    /// @param user Address of user
    /// @param activity Activity name
    /// @param target Achieved target
    event TargetAchieved(address indexed user, string indexed activity, uint indexed target);

    /// @notice Error thrown when no target is set an activity
    /// @param activity Activity name
    error TargetNotSet(string activity);

    /// @notice Error thrown when target is already reached while attempting to record activity
    /// @param activity Activity name
    /// @param target Target reached
    error TargetAlreadyReached(string activity, uint target);

    /// @notice Get target set for activity
    /// @param _activity Activity name
    /// @return target Target set for the activity
    function getTarget(string calldata _activity) external view returns (uint) {
        return activityTargets[msg.sender][_activity];
    }

    /// @notice Get units completed for activity
    /// @param _activity Activity name
    /// @return units Units completed
    function getUnits(string calldata _activity) external view returns (uint) {
        return activityUnits[msg.sender][_activity];
    }

    /// @notice Set a new target for an activity
    /// @param _activity Activity name
    /// @param _target New target for activity
    function setTarget(string calldata _activity, uint _target) external {
        activityTargets[msg.sender][_activity] = _target;
        emit TargetSet(msg.sender, _activity, _target);
    }

    /// @notice Record an activity by user
    /// @param _activity Activity name
    /// @param _units Units of activity completed
    /// @custom:error TargetNotSet if not target is set for `_activity`
    /// @custom:error TargetAlreadyReached if target is already reached for `_activity`
    function recordActivity(string calldata _activity, uint _units) external {
        require(_units > 0, "units must be greater than 0.");
        
        uint target = activityTargets[msg.sender][_activity];
        if (target == 0) {
            revert TargetNotSet(_activity);
        }
        
        uint oldUnits = activityUnits[msg.sender][_activity];
        if (oldUnits >= target) {
            revert TargetAlreadyReached(_activity, target);
        }

        activityUnits[msg.sender][_activity] += _units;

        emit ActivityRecorded(msg.sender, _activity, oldUnits);
        
        if (activityUnits[msg.sender][_activity] >= target) {
            emit TargetAchieved(msg.sender, _activity, target);
        }
    }
}