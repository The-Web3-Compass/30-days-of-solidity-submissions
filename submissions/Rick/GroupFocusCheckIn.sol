// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GroupFocusCheckIn
 * @notice 群体专注学习打卡合约
 * @dev 管理者可以创建多种主题活动，参与者质押ETH参与，打卡成功后返还，失败者资金分配给成功者
 */
contract GroupFocusCheckIn is ReentrancyGuard, Ownable {
    
    // 活动结构体
    struct Activity {
        uint256 activityId;           // 活动ID
        string name;                  // 活动名称（如：每日早起打卡）
        uint256 stakeAmount;          // 质押金额（wei）
        uint256 startTime;            // 打卡开始时间（每天的时间戳，例如早上6点）
        uint256 endTime;              // 打卡结束时间（每天的时间戳，例如早上8点）
        address creator;              // 创建者
        bool isActive;                // 活动是否激活
        uint256 createdAt;            // 创建时间
    }
    
    // 参与者打卡记录
    struct CheckInRecord {
        address participant;          // 参与者地址
        uint256 activityId;           // 活动ID
        uint256 date;                // 日期（Unix时间戳，去掉时分秒，只保留日期）
        bool hasCheckedIn;            // 是否已打卡
        bool hasStaked;               // 是否已质押
        uint256 stakeTime;            // 质押时间
    }
    
    // 每日结算记录
    struct DailySettlement {
        uint256 date;                 // 日期
        uint256 activityId;           // 活动ID
        bool isSettled;               // 是否已结算
        uint256 totalStaked;          // 总质押金额
        uint256 successCount;         // 打卡成功人数
        uint256 failedCount;          // 打卡失败人数
        uint256 contractFee;          // 合约抽成
        uint256 rewardPool;           // 奖励池（失败者的80%）
    }
    
    // 活动映射
    mapping(uint256 => Activity) public activities;
    uint256 public nextActivityId;
    
    // 参与者记录：参与者地址 => 活动ID => 日期 => 打卡记录
    mapping(address => mapping(uint256 => mapping(uint256 => CheckInRecord))) public checkInRecords;
    
    // 每日结算记录：活动ID => 日期 => 结算记录
    mapping(uint256 => mapping(uint256 => DailySettlement)) public dailySettlements;
    
    // 用户参与的活动列表
    mapping(address => uint256[]) public userActivities;
    
    // 活动的参与者列表
    mapping(uint256 => address[]) public activityParticipants;
    
    // 事件定义
    /**
     * @notice 活动创建事件
     * @param activityId 活动ID（索引字段，便于快速检索）
     * @param name 活动名称
     * @param stakeAmount 质押金额（wei）
     * @param creator 创建者地址（索引字段，便于快速检索）
     * @param createdAt 创建时间戳
     */
    event ActivityCreated(
        uint256 indexed activityId,
        string name,
        uint256 stakeAmount,
        address indexed creator,
        uint256 createdAt
    );
    
    /**
     * @notice 用户参与活动事件
     * @param participant 参与者地址（索引字段，便于快速检索）
     * @param activityId 活动ID（索引字段，便于快速检索）
     * @param stakeAmount 质押金额（wei）
     * @param date 参与的活动日期（Unix时间戳，去掉时分秒，只保留日期）
     *             用户今天参与，date为明天的日期；用户需要在该日期进行打卡
     */
    event ParticipantJoined(
        address indexed participant,
        uint256 indexed activityId,
        uint256 stakeAmount,
        uint256 date
    );
    
    /**
     * @notice 打卡成功事件
     * @param participant 参与者地址（索引字段，便于快速检索）
     * @param activityId 活动ID（索引字段，便于快速检索）
     * @param date 打卡日期（Unix时间戳，去掉时分秒，只保留日期）
     * @param timestamp 打卡时间戳（精确到秒）
     */
    event CheckInSuccess(
        address indexed participant,
        uint256 indexed activityId,
        uint256 date,
        uint256 timestamp
    );
    
    /**
     * @notice 每日结算完成事件
     * @param activityId 活动ID（索引字段，便于快速检索）
     * @param date 结算日期（Unix时间戳，去掉时分秒，只保留日期）
     * @param successCount 打卡成功人数
     * @param failedCount 打卡失败人数
     * @param contractFee 合约抽成金额（失败者质押的20%，wei）
     * @param rewardPool 奖励池金额（失败者质押的80%，wei）
     */
    event DailySettled(
        uint256 indexed activityId,
        uint256 date,
        uint256 successCount,
        uint256 failedCount,
        uint256 contractFee,
        uint256 rewardPool
    );
    
    /**
     * @notice 质押金返还事件
     * @param participant 参与者地址（索引字段，便于快速检索）
     * @param activityId 活动ID（索引字段，便于快速检索）
     * @param date 结算日期（Unix时间戳，去掉时分秒，只保留日期）
     * @param amount 返还金额（扣除gas费后的质押金，wei）
     */
    event Refunded(
        address indexed participant,
        uint256 indexed activityId,
        uint256 date,
        uint256 amount
    );
    
    /**
     * @notice 奖励分配事件
     * @param participant 参与者地址（索引字段，便于快速检索）
     * @param activityId 活动ID（索引字段，便于快速检索）
     * @param date 结算日期（Unix时间戳，去掉时分秒，只保留日期）
     * @param rewardAmount 分配的奖励金额（失败者质押的80%均分，wei）
     */
    event RewardDistributed(
        address indexed participant,
        uint256 indexed activityId,
        uint256 date,
        uint256 rewardAmount
    );
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @notice 创建新活动
     * @param _name 活动名称
     * @param _stakeAmount 质押金额（wei）
     * @param _startTime 每天打卡开始时间（秒，例如6*3600表示早上6点）
     * @param _endTime 每天打卡结束时间（秒，例如8*3600表示早上8点）
     */
    function createActivity(
        string memory _name,
        uint256 _stakeAmount,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner returns (uint256) {
        require(_stakeAmount > 0, "Stake amount must be greater than 0");
        require(_startTime < _endTime, "Start time must be before end time");
        require(_startTime < 86400 && _endTime < 86400, "Time must be within 24 hours");
        
        uint256 activityId = nextActivityId;
        nextActivityId++;
        
        activities[activityId] = Activity({
            activityId: activityId,
            name: _name,
            stakeAmount: _stakeAmount,
            startTime: _startTime,
            endTime: _endTime,
            creator: msg.sender,
            isActive: true,
            createdAt: block.timestamp
        });
        
        emit ActivityCreated(activityId, _name, _stakeAmount, msg.sender, block.timestamp);
        
        return activityId;
    }
    
    /**
     * @notice 参与明天的活动并质押ETH
     * @dev 用户每天只能选择是否参加第二天的打卡活动，每次参与都需要重新质押
     *      如果要参加第三天的活动，需要在第二天重新报名
     * @param _activityId 活动ID
     */
    function joinActivity(uint256 _activityId) external payable nonReentrant {
        Activity storage activity = activities[_activityId];
        require(activity.isActive, "Activity is not active");
        require(msg.value == activity.stakeAmount, "Stake amount mismatch");
        
        uint256 tomorrow = getTodayTimestamp() + 1 days;
        
        // 检查是否已经参与明天的活动
        require(
            !checkInRecords[msg.sender][_activityId][tomorrow].hasStaked,
            "Already joined tomorrow's activity"
        );
        
        // 记录参与者（参与明天的活动）
        checkInRecords[msg.sender][_activityId][tomorrow] = CheckInRecord({
            participant: msg.sender,
            activityId: _activityId,
            date: tomorrow,
            hasCheckedIn: false,
            hasStaked: true,
            stakeTime: block.timestamp
        });
        
        // 添加到参与者列表（如果还没有添加过这个活动）
        bool alreadyAdded = false;
        for (uint256 i = 0; i < activityParticipants[_activityId].length; i++) {
            if (activityParticipants[_activityId][i] == msg.sender) {
                alreadyAdded = true;
                break;
            }
        }
        if (!alreadyAdded) {
            activityParticipants[_activityId].push(msg.sender);
        }
        
        // 添加到用户活动列表
        bool activityExists = false;
        for (uint256 i = 0; i < userActivities[msg.sender].length; i++) {
            if (userActivities[msg.sender][i] == _activityId) {
                activityExists = true;
                break;
            }
        }
        if (!activityExists) {
            userActivities[msg.sender].push(_activityId);
        }
        
        emit ParticipantJoined(msg.sender, _activityId, msg.value, tomorrow);
    }
    
    /**
     * @notice 打卡
     * @dev 用户在参与活动的当天，在指定时间窗口内进行打卡
     *      例如：用户昨天参与今天的活动，今天在时间窗口内打卡
     * @param _activityId 活动ID
     */
    function checkIn(uint256 _activityId) external {
        Activity storage activity = activities[_activityId];
        require(activity.isActive, "Activity is not active");
        
        uint256 today = getTodayTimestamp();
        CheckInRecord storage record = checkInRecords[msg.sender][_activityId][today];
        
        require(record.hasStaked, "Must stake first");
        require(!record.hasCheckedIn, "Already checked in today");
        
        // 检查是否在打卡时间窗口内
        uint256 currentTimeOfDay = getCurrentTimeOfDay();
        require(
            currentTimeOfDay >= activity.startTime && currentTimeOfDay <= activity.endTime,
            "Not in check-in time window"
        );
        
        record.hasCheckedIn = true;
        
        emit CheckInSuccess(msg.sender, _activityId, today, block.timestamp);
    }
    
    /**
     * @notice 结算昨天的活动
     * @param _activityId 活动ID
     */
    function settleYesterday(uint256 _activityId) external nonReentrant {
        Activity storage activity = activities[_activityId];
        require(activity.isActive, "Activity is not active");
        
        uint256 yesterday = getTodayTimestamp() - 1 days;
        DailySettlement storage settlement = dailySettlements[_activityId][yesterday];
        
        require(!settlement.isSettled, "Already settled");
        
        // 统计打卡情况
        uint256 successCount = 0;
        uint256 failedCount = 0;
        uint256 totalStaked = 0;
        address[] memory participants = activityParticipants[_activityId];
        
        // 收集成功和失败的参与者
        address[] memory successParticipants = new address[](participants.length);
        address[] memory failedParticipants = new address[](participants.length);
        
        for (uint256 i = 0; i < participants.length; i++) {
            CheckInRecord storage record = checkInRecords[participants[i]][_activityId][yesterday];
            
            if (record.hasStaked) {
                totalStaked += activity.stakeAmount;
                
                if (record.hasCheckedIn) {
                    successParticipants[successCount] = participants[i];
                    successCount++;
                } else {
                    failedParticipants[failedCount] = participants[i];
                    failedCount++;
                }
            }
        }
        
        // 计算资金分配
        uint256 failedStakeTotal = failedCount * activity.stakeAmount;
        uint256 contractFee = (failedStakeTotal * 20) / 100; // 20% 合约抽成
        uint256 rewardPool = (failedStakeTotal * 80) / 100; // 80% 奖励池
        
        // 计算总gas费（从成功者的总质押中扣除）
        uint256 gasFeePerTransaction = 0.0001 ether; // 估算每次转账的gas费
        uint256 totalGasFee = successCount * gasFeePerTransaction;
        uint256 successStakeTotal = successCount * activity.stakeAmount;
        
        // 成功者可返还的总金额 = 总质押 - gas费 + 奖励池
        uint256 totalRefundable = successStakeTotal > totalGasFee 
            ? successStakeTotal - totalGasFee + rewardPool 
            : rewardPool;
        
        settlement.date = yesterday;
        settlement.activityId = _activityId;
        settlement.isSettled = true;
        settlement.totalStaked = totalStaked;
        settlement.successCount = successCount;
        settlement.failedCount = failedCount;
        settlement.contractFee = contractFee;
        settlement.rewardPool = rewardPool;
        
        // 分配资金给成功者
        if (successCount > 0 && totalRefundable > 0) {
            uint256 refundPerPerson = totalRefundable / successCount;
            uint256 refundAmountPerPerson = (successStakeTotal > totalGasFee) 
                ? (successStakeTotal - totalGasFee) / successCount 
                : 0;
            uint256 rewardPerPerson = rewardPool / successCount;
            
            // 返还成功者的质押金并分配奖励
            for (uint256 i = 0; i < successCount; i++) {
                address participant = successParticipants[i];
                
                if (refundPerPerson > 0) {
                    (bool success, ) = payable(participant).call{value: refundPerPerson}("");
                    require(success, "Refund failed");
                    
                    if (refundAmountPerPerson > 0) {
                        emit Refunded(participant, _activityId, yesterday, refundAmountPerPerson);
                    }
                    if (rewardPerPerson > 0) {
                        emit RewardDistributed(participant, _activityId, yesterday, rewardPerPerson);
                    }
                }
            }
        }
        
        emit DailySettled(
            _activityId,
            yesterday,
            successCount,
            failedCount,
            contractFee,
            rewardPool
        );
    }
    
    /**
     * @notice 提取合约抽成（仅管理员）
     */
    function withdrawContractFee() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
    
    /**
     * @notice 停用活动
     * @param _activityId 活动ID
     */
    function deactivateActivity(uint256 _activityId) external onlyOwner {
        activities[_activityId].isActive = false;
    }
    
    /**
     * @notice 激活活动
     * @param _activityId 活动ID
     */
    function activateActivity(uint256 _activityId) external onlyOwner {
        activities[_activityId].isActive = true;
    }
    
    /**
     * @notice 获取今天的0点时间戳
     */
    function getTodayTimestamp() public view returns (uint256) {
        // 计算今天0点的时间戳
        uint256 daySeconds = 86400; // 一天的秒数
        uint256 today = (block.timestamp / daySeconds) * daySeconds;
        // 转换为UTC+0的日期（可以根据需要调整时区）
        return today;
    }
    
    /**
     * @notice 获取当前时间在一天中的秒数（0-86399）
     */
    function getCurrentTimeOfDay() public view returns (uint256) {
        return block.timestamp % 86400;
    }
    
    /**
     * @notice 查询用户在某天的打卡状态
     */
    function getUserCheckInStatus(
        address _user,
        uint256 _activityId,
        uint256 _date
    ) external view returns (bool hasStaked, bool hasCheckedIn) {
        CheckInRecord storage record = checkInRecords[_user][_activityId][_date];
        return (record.hasStaked, record.hasCheckedIn);
    }
    
    /**
     * @notice 查询活动的结算信息
     */
    function getSettlementInfo(
        uint256 _activityId,
        uint256 _date
    ) external view returns (DailySettlement memory) {
        return dailySettlements[_activityId][_date];
    }
    
    /**
     * @notice 获取活动的参与者数量
     */
    function getActivityParticipantCount(uint256 _activityId) external view returns (uint256) {
        return activityParticipants[_activityId].length;
    }
    
    /**
     * @notice 获取用户参与的所有活动ID
     */
    function getUserActivities(address _user) external view returns (uint256[] memory) {
        return userActivities[_user];
    }
    
    // 接收ETH
    receive() external payable {}
}

