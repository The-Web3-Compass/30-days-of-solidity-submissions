# ActivityTracker Smart Contract

## Overview
`ActivityTracker.sol` is a Solidity smart contract that allows users to log their workout sessions on-chain and tracks their fitness progress. The contract is designed for decentralized fitness tracking applications, enabling users to record workouts, monitor achievements, and unlock milestones, all while emitting events that can be easily filtered by off-chain tools or frontends.

## Features
- **Workout Logging:** Users can log each workout session, specifying the type, duration (in minutes), and calories burned.
- **Progress Tracking:** The contract tracks each user's total workouts, total minutes exercised, and total calories burned.
- **Milestone Events:**
  - Emits an event when a user completes 10 workouts in a single week.
  - Emits an event when a user surpasses 500 total workout minutes.
- **Indexed Events:** Events use `indexed` parameters for efficient filtering by user address and milestone.
- **View Functions:**
  - Retrieve all workouts for a user.
  - Retrieve summary statistics (total workouts, minutes, calories) for a user.

## Key Data Structures
- `Workout`: Struct containing workout type, duration, calories, and timestamp.
- `UserStats`: Struct tracking total workouts, minutes, calories, and weekly workout counts (by week number).

## Main Functions
- `logWorkout(string calldata _workoutType, uint256 _duration, uint256 _calories)`: Logs a workout for the sender, updates stats, and emits milestone events if goals are reached.
- `getUserWorkouts(address user)`: Returns an array of all workouts logged by the specified user.
- `getUserStats(address user)`: Returns the user's total workouts, total minutes, and total calories.
- `getWeek(uint256 timestamp)`: Helper function to calculate the week number since the Unix epoch.

## Events
- `WorkoutLogged(address indexed user, string workoutType, uint256 duration, uint256 calories, uint256 timestamp)`
- `WeeklyGoalReached(address indexed user, uint256 indexed week, uint256 workouts)`
- `TotalMinutesGoalReached(address indexed user, uint256 totalMinutes)`

## Usage Example
1. **Log a Workout:**
   ```solidity
   activityTracker.logWorkout("Running", 45, 400);
   ```
2. **Listen for Events:**
   Off-chain tools or frontends can filter for `WeeklyGoalReached` or `TotalMinutesGoalReached` events by user address.

## Security Notes
- Only the user themselves can log their workouts.
- The contract does not support deleting or editing past workouts.

## License
MIT