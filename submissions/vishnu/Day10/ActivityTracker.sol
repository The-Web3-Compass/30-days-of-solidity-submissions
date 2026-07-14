// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ActivityTracker {
    enum WorkoutType { Running, Cycling, Swimming, WeightLifting, Yoga, Walking, Boxing, Dancing }
    
    struct WorkoutSession {
        uint sessionId;
        address user;
        WorkoutType workoutType;
        uint duration;        // in minutes
        uint calories;        // calories burned
        uint timestamp;       // when workout was logged
        string notes;         // optional workout notes
    }
    
    struct UserStats {
        uint totalWorkouts;
        uint totalMinutes;
        uint totalCalories;
        uint weeklyWorkouts;
        uint weeklyMinutes;
        uint weeklyCalories;
        uint lastWorkoutTimestamp;
        uint weekStart;       
        bool[] goalsAchieved; 
    }
    
    
    enum GoalType { 
        WeeklyWorkouts10,     
        WeeklyMinutes500,     
        TotalWorkouts50,      
        TotalMinutes1000,     
        WeeklyCalories3000,   
        TotalCalories10000,   
        ConsistentWeek,       
        Marathon,             
        Dedication,           
        Elite                 
    }
    
    
    uint public totalSessions;
    mapping(address => UserStats) public userStats;
    mapping(uint => WorkoutSession) public workoutSessions;
    mapping(address => uint[]) public userSessionIds;
    
   
    mapping(GoalType => uint) public goalThresholds;
    
    event WorkoutLogged(
        address indexed user,
        uint indexed sessionId,
        WorkoutType indexed workoutType,
        uint duration,
        uint calories,
        uint timestamp
    );
    
    event GoalAchieved(
        address indexed user,
        GoalType indexed goalType,
        uint indexed achievementTimestamp,
        uint currentValue,
        string message
    );
    
    event WeeklyStatsReset(
        address indexed user,
        uint indexed weekNumber,
        uint previousWeekWorkouts,
        uint previousWeekMinutes
    );
    
    event PersonalRecord(
        address indexed user,
        WorkoutType indexed workoutType,
        string recordType, 
        uint newRecord,
        uint previousRecord
    );
    
    event MilestoneReached(
        address indexed user,
        string indexed milestoneType, 
        uint indexed milestoneValue,
        uint timestamp
    );
    
    constructor() {
        
        goalThresholds[GoalType.WeeklyWorkouts10] = 10;
        goalThresholds[GoalType.WeeklyMinutes500] = 500;
        goalThresholds[GoalType.TotalWorkouts50] = 50;
        goalThresholds[GoalType.TotalMinutes1000] = 1000;
        goalThresholds[GoalType.WeeklyCalories3000] = 3000;
        goalThresholds[GoalType.TotalCalories10000] = 10000;
        goalThresholds[GoalType.ConsistentWeek] = 7;
        goalThresholds[GoalType.Marathon] = 180;
        goalThresholds[GoalType.Dedication] = 100;
        goalThresholds[GoalType.Elite] = 5000;
    }
    
   
    function logWorkout(
        WorkoutType _workoutType,
        uint _duration,
        uint _calories,
        string memory _notes
    ) external {
        require(_duration > 0, "Duration must be greater than 0");
        require(_calories > 0, "Calories must be greater than 0");
        
       
        uint sessionId = totalSessions++;
        WorkoutSession memory newSession = WorkoutSession({
            sessionId: sessionId,
            user: msg.sender,
            workoutType: _workoutType,
            duration: _duration,
            calories: _calories,
            timestamp: block.timestamp,
            notes: _notes
        });
        
        
        workoutSessions[sessionId] = newSession;
        userSessionIds[msg.sender].push(sessionId);
        
        
        _updateUserStats(msg.sender, _duration, _calories);
        
        
        emit WorkoutLogged(
            msg.sender,
            sessionId,
            _workoutType,
            _duration,
            _calories,
            block.timestamp
        );
        
        
        _checkGoals(msg.sender, _duration);
        _checkPersonalRecords(msg.sender, _workoutType, _duration, _calories);
        _checkMilestones(msg.sender);
    }
    
    
    function _updateUserStats(
        address _user, 
        uint _duration, 
        uint _calories
    ) internal {
        UserStats storage stats = userStats[_user];
        
       
        uint currentWeekStart = (block.timestamp / 1 weeks) * 1 weeks;
        if (stats.weekStart < currentWeekStart) {
          
            emit WeeklyStatsReset(
                _user,
                currentWeekStart / 1 weeks,
                stats.weeklyWorkouts,
                stats.weeklyMinutes
            );
            
            
            stats.weeklyWorkouts = 0;
            stats.weeklyMinutes = 0;
            stats.weeklyCalories = 0;
            stats.weekStart = currentWeekStart;
        }
        
    
        stats.totalWorkouts++;
        stats.totalMinutes += _duration;
        stats.totalCalories += _calories;
        stats.weeklyWorkouts++;
        stats.weeklyMinutes += _duration;
        stats.weeklyCalories += _calories;
        stats.lastWorkoutTimestamp = block.timestamp;
        
       
        if (stats.goalsAchieved.length == 0) {
            stats.goalsAchieved = new bool[](10); 
        }
    }
    

    function _checkGoals(
        address _user, 
        uint _duration
    ) internal {
        UserStats storage stats = userStats[_user];
        
        if (!stats.goalsAchieved[uint(GoalType.WeeklyWorkouts10)] && 
            stats.weeklyWorkouts >= goalThresholds[GoalType.WeeklyWorkouts10]) {
            stats.goalsAchieved[uint(GoalType.WeeklyWorkouts10)] = true;
            emit GoalAchieved(
                _user,
                GoalType.WeeklyWorkouts10,
                block.timestamp,
                stats.weeklyWorkouts,
                "Congratulations! 10 workouts in a week!"
            );
        }
        
        if (!stats.goalsAchieved[uint(GoalType.WeeklyMinutes500)] && 
            stats.weeklyMinutes >= goalThresholds[GoalType.WeeklyMinutes500]) {
            stats.goalsAchieved[uint(GoalType.WeeklyMinutes500)] = true;
            emit GoalAchieved(
                _user,
                GoalType.WeeklyMinutes500,
                block.timestamp,
                stats.weeklyMinutes,
                "Amazing! 500 minutes of exercise this week!"
            );
        }
        
        if (!stats.goalsAchieved[uint(GoalType.TotalWorkouts50)] && 
            stats.totalWorkouts >= goalThresholds[GoalType.TotalWorkouts50]) {
            stats.goalsAchieved[uint(GoalType.TotalWorkouts50)] = true;
            emit GoalAchieved(
                _user,
                GoalType.TotalWorkouts50,
                block.timestamp,
                stats.totalWorkouts,
                "Fantastic! 50 total workouts completed!"
            );
        }
        
        if (!stats.goalsAchieved[uint(GoalType.TotalMinutes1000)] && 
            stats.totalMinutes >= goalThresholds[GoalType.TotalMinutes1000]) {
            stats.goalsAchieved[uint(GoalType.TotalMinutes1000)] = true;
            emit GoalAchieved(
                _user,
                GoalType.TotalMinutes1000,
                block.timestamp,
                stats.totalMinutes,
                "Incredible! 1000 total minutes of fitness!"
            );
        }
        
        // Check Weekly Calories Goal (3000 calories)
        if (!stats.goalsAchieved[uint(GoalType.WeeklyCalories3000)] && 
            stats.weeklyCalories >= goalThresholds[GoalType.WeeklyCalories3000]) {
            stats.goalsAchieved[uint(GoalType.WeeklyCalories3000)] = true;
            emit GoalAchieved(
                _user,
                GoalType.WeeklyCalories3000,
                block.timestamp,
                stats.weeklyCalories,
                "Outstanding! 3000 calories burned this week!"
            );
        }
        
        if (!stats.goalsAchieved[uint(GoalType.Marathon)] && 
            _duration >= goalThresholds[GoalType.Marathon]) {
            stats.goalsAchieved[uint(GoalType.Marathon)] = true;
            emit GoalAchieved(
                _user,
                GoalType.Marathon,
                block.timestamp,
                _duration,
                "Marathon Achievement! 3+ hour workout completed!"
            );
        }
        
        _checkAdvancedGoals(_user);
    }
    

    function _checkAdvancedGoals(address _user) internal {
        UserStats storage stats = userStats[_user];
        
        if (!stats.goalsAchieved[uint(GoalType.TotalCalories10000)] && 
            stats.totalCalories >= goalThresholds[GoalType.TotalCalories10000]) {
            stats.goalsAchieved[uint(GoalType.TotalCalories10000)] = true;
            emit GoalAchieved(
                _user,
                GoalType.TotalCalories10000,
                block.timestamp,
                stats.totalCalories,
                "Epic Achievement! 10,000 total calories burned!"
            );
        }
        
        // Check Dedication Goal (100 total workouts)
        if (!stats.goalsAchieved[uint(GoalType.Dedication)] && 
            stats.totalWorkouts >= goalThresholds[GoalType.Dedication]) {
            stats.goalsAchieved[uint(GoalType.Dedication)] = true;
            emit GoalAchieved(
                _user,
                GoalType.Dedication,
                block.timestamp,
                stats.totalWorkouts,
                "Dedication Master! 100 total workouts!"
            );
        }
        
        if (!stats.goalsAchieved[uint(GoalType.Elite)] && 
            stats.totalMinutes >= goalThresholds[GoalType.Elite]) {
            stats.goalsAchieved[uint(GoalType.Elite)] = true;
            emit GoalAchieved(
                _user,
                GoalType.Elite,
                block.timestamp,
                stats.totalMinutes,
                "Elite Status! 5,000 total minutes of fitness!"
            );
        }
    }
    
    function _checkPersonalRecords(
        address _user, 
        WorkoutType _workoutType, 
        uint _duration, 
        uint _calories
    ) internal {
        uint[] memory sessionIds = userSessionIds[_user];
        uint longestDuration = 0;
        uint mostCalories = 0;
        
        for (uint i = 0; i < sessionIds.length - 1; i++) { 
            WorkoutSession memory session = workoutSessions[sessionIds[i]];
            if (session.workoutType == _workoutType) {
                if (session.duration > longestDuration) {
                    longestDuration = session.duration;
                }
                if (session.calories > mostCalories) {
                    mostCalories = session.calories;
                }
            }
        }
        
        if (_duration > longestDuration && longestDuration > 0) {
            emit PersonalRecord(
                _user,
                _workoutType,
                "longest_duration",
                _duration,
                longestDuration
            );
        }
        
        if (_calories > mostCalories && mostCalories > 0) {
            emit PersonalRecord(
                _user,
                _workoutType,
                "most_calories",
                _calories,
                mostCalories
            );
        }
    }
    
    function _checkMilestones(address _user) internal {
        UserStats memory stats = userStats[_user];
        
        // Milestone checkpoints
        uint[] memory workoutMilestones = new uint[](5);
        workoutMilestones[0] = 10;
        workoutMilestones[1] = 25;
        workoutMilestones[2] = 50;
        workoutMilestones[3] = 100;
        workoutMilestones[4] = 250;
        
        uint[] memory minuteMilestones = new uint[](5);
        minuteMilestones[0] = 100;
        minuteMilestones[1] = 500;
        minuteMilestones[2] = 1000;
        minuteMilestones[3] = 2500;
        minuteMilestones[4] = 5000;

        for (uint i = 0; i < workoutMilestones.length; i++) {
            if (stats.totalWorkouts == workoutMilestones[i]) {
                emit MilestoneReached(
                    _user,
                    "workouts",
                    workoutMilestones[i],
                    block.timestamp
                );
            }
        }

        for (uint i = 0; i < minuteMilestones.length; i++) {
            if (stats.totalMinutes >= minuteMilestones[i] && 
                stats.totalMinutes - stats.totalMinutes < minuteMilestones[i]) {
                emit MilestoneReached(
                    _user,
                    "minutes",
                    minuteMilestones[i],
                    block.timestamp
                );
            }
        }
    }
    

    function getUserStats(address _user) external view returns (
        uint totalWorkouts,
        uint totalMinutes,
        uint totalCalories,
        uint weeklyWorkouts,
        uint weeklyMinutes,
        uint weeklyCalories,
        uint lastWorkoutTimestamp
    ) {
        UserStats memory stats = userStats[_user];
        return (
            stats.totalWorkouts,
            stats.totalMinutes,
            stats.totalCalories,
            stats.weeklyWorkouts,
            stats.weeklyMinutes,
            stats.weeklyCalories,
            stats.lastWorkoutTimestamp
        );
    }
    

    function getUserWorkouts(address _user) external view returns (uint[] memory) {
        return userSessionIds[_user];
    }
    

    function getWorkoutSession(uint _sessionId) external view returns (
        address user,
        WorkoutType workoutType,
        uint duration,
        uint calories,
        uint timestamp,
        string memory notes
    ) {
        WorkoutSession memory session = workoutSessions[_sessionId];
        return (
            session.user,
            session.workoutType,
            session.duration,
            session.calories,
            session.timestamp,
            session.notes
        );
    }
    

    function hasAchievedGoal(address _user, GoalType _goalType) external view returns (bool) {
        UserStats memory stats = userStats[_user];
        if (stats.goalsAchieved.length > uint(_goalType)) {
            return stats.goalsAchieved[uint(_goalType)];
        }
        return false;
    }
 
    function getWorkoutTypeName(WorkoutType _workoutType) external pure returns (string memory) {
        if (_workoutType == WorkoutType.Running) return "Running";
        if (_workoutType == WorkoutType.Cycling) return "Cycling";
        if (_workoutType == WorkoutType.Swimming) return "Swimming";
        if (_workoutType == WorkoutType.WeightLifting) return "Weight Lifting";
        if (_workoutType == WorkoutType.Yoga) return "Yoga";
        if (_workoutType == WorkoutType.Walking) return "Walking";
        if (_workoutType == WorkoutType.Boxing) return "Boxing";
        if (_workoutType == WorkoutType.Dancing) return "Dancing";
        return "Unknown";
    }
    
    function getRecentWorkouts() external view returns (uint[10] memory) {
        uint[10] memory recentSessions;
        uint startIndex = totalSessions > 10 ? totalSessions - 10 : 0;
        uint count = 0;
        
        for (uint i = totalSessions; i > startIndex; i--) {
            recentSessions[count] = i - 1;
            count++;
        }
        
        return recentSessions;
    }
}
