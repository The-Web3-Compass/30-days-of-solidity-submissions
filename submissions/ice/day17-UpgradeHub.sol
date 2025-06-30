/**
 * @title UpgradeHub
 * @dev 可升级的订阅管理器
 * 为某在线新闻dApp 提供订阅管理服务。
 * 功能点：
 * 1. The proxy contract 代理合同存储用户订阅信息（如订阅、续订和到期日期），
 * 2. an external logic contract. 外部逻辑合同中管理订阅的逻辑（订阅、升级用户、暂停帐户）。
 * 3. a new logic contract当需要添加新功能或修复错误时，只需部署一个新的 logic contract，并使用 'delegatecall' 将代理指向它，而无需迁移任何数据。
 * 
 * 将存储与逻辑分离以实现长期可维护性。delegate call for upgrades/proxy pattern/Upgradeable contracts
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SubscriptionStorage
 * @dev 定义订阅系统的存储布局
 */
contract SubscriptionStorage {
    // 存储所有者地址
    address public owner;
    
    // 存储当前逻辑合约地址
    address public logicContract;
    
    // 订阅级别
    enum SubscriptionLevel { None, Basic, Premium, Enterprise }
    
    // 用户订阅信息
    struct Subscription {
        SubscriptionLevel level;
        uint256 startDate;
        uint256 expiryDate;
        bool isPaused;
        bool isActive;
    }
    
    // 用户地址 => 订阅信息
    mapping(address => Subscription) public subscriptions;
    
    // 所有订阅者地址
    address[] public subscribers;
    
    // 订阅价格 (wei)
    mapping(SubscriptionLevel => uint256) public subscriptionPrices;
    
    // 暂停的用户
    mapping(address => bool) public pausedUsers;
    
    // 事件
    event SubscriptionCreated(address indexed user, SubscriptionLevel level, uint256 expiryDate);
    event SubscriptionRenewed(address indexed user, SubscriptionLevel level, uint256 newExpiryDate);
    event SubscriptionUpgraded(address indexed user, SubscriptionLevel oldLevel, SubscriptionLevel newLevel);
    event SubscriptionPaused(address indexed user);
    event SubscriptionResumed(address indexed user);
    event LogicContractUpgraded(address indexed oldLogic, address indexed newLogic);
}

/**
 * @title SubscriptionProxy
 * @dev 代理合约，存储数据并将逻辑调用委托给逻辑合约
 */
contract SubscriptionProxy is SubscriptionStorage {
    constructor(address _initialLogicContract) {
        require(_initialLogicContract != address(0), "Invalid logic contract address");
        owner = msg.sender;
        logicContract = _initialLogicContract;
        
        // 初始化订阅价格
        subscriptionPrices[SubscriptionLevel.Basic] = 0.01 ether;
        subscriptionPrices[SubscriptionLevel.Premium] = 0.05 ether;
        subscriptionPrices[SubscriptionLevel.Enterprise] = 0.1 ether;
    }
    
    // 只有所有者可以调用的修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev 升级逻辑合约
     * @param _newLogicContract 新的逻辑合约地址
     */
    function upgradeLogicContract(address _newLogicContract) external onlyOwner {
        require(_newLogicContract != address(0), "Invalid logic contract address");
        address oldLogic = logicContract;
        logicContract = _newLogicContract;
        emit LogicContractUpgraded(oldLogic, _newLogicContract);
    }
    
    /**
     * @dev 回退函数，将所有调用委托给逻辑合约
     */
    fallback() external payable {
        address _impl = logicContract;
        require(_impl != address(0), "Logic contract not set");
        
        assembly {
            // 复制调用数据
            calldatacopy(0, 0, calldatasize())
            
            // 执行delegatecall
            let success := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            
            // 复制返回数据
            returndatacopy(0, 0, returndatasize())
            
            // 根据调用结果返回或回滚
            switch success
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    /**
     * @dev 接收ETH的函数
     */
    receive() external payable {}
}

/**
 * @title SubscriptionLogic
 * @dev 第一版逻辑合约，实现订阅管理的核心功能
 */
contract SubscriptionLogic is SubscriptionStorage {
    /**
     * @dev 创建新订阅
     * @param level 订阅级别
     * @param durationMonths 订阅时长（月）
     */
    function subscribe(SubscriptionLevel level, uint256 durationMonths) external payable {
        require(level != SubscriptionLevel.None, "Invalid subscription level");
        require(durationMonths > 0, "Duration must be greater than 0");
        require(!subscriptions[msg.sender].isActive, "Subscription already exists");
        
        uint256 price = subscriptionPrices[level] * durationMonths;
        require(msg.value >= price, "Insufficient payment");
        
        // 计算到期日期（简化：1个月=30天）
        uint256 expiryDate = block.timestamp + (durationMonths * 30 days);
        
        // 创建订阅
        subscriptions[msg.sender] = Subscription({
            level: level,
            startDate: block.timestamp,
            expiryDate: expiryDate,
            isPaused: false,
            isActive: true
        });
        
        // 添加到订阅者列表
        subscribers.push(msg.sender);
        
        // 退还多余的ETH
        uint256 excess = msg.value - price;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
        
        emit SubscriptionCreated(msg.sender, level, expiryDate);
    }
    
    /**
     * @dev 续订订阅
     * @param durationMonths 续订时长（月）
     */
    function renewSubscription(uint256 durationMonths) external payable {
        require(subscriptions[msg.sender].isActive, "No active subscription");
        require(durationMonths > 0, "Duration must be greater than 0");
        
        SubscriptionLevel level = subscriptions[msg.sender].level;
        uint256 price = subscriptionPrices[level] * durationMonths;
        require(msg.value >= price, "Insufficient payment");
        
        // 计算新的到期日期
        uint256 newExpiryDate = subscriptions[msg.sender].expiryDate;
        if (newExpiryDate < block.timestamp) {
            newExpiryDate = block.timestamp;
        }
        newExpiryDate += (durationMonths * 30 days);
        
        // 更新订阅
        subscriptions[msg.sender].expiryDate = newExpiryDate;
        
        // 退还多余的ETH
        uint256 excess = msg.value - price;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
        
        emit SubscriptionRenewed(msg.sender, level, newExpiryDate);
    }
    
    /**
     * @dev 升级订阅级别
     * @param newLevel 新的订阅级别
     */
    function upgradeSubscription(SubscriptionLevel newLevel) external payable {
        require(subscriptions[msg.sender].isActive, "No active subscription");
        require(newLevel > subscriptions[msg.sender].level, "Can only upgrade to higher level");
        
        SubscriptionLevel oldLevel = subscriptions[msg.sender].level;
        uint256 remainingTime = subscriptions[msg.sender].expiryDate - block.timestamp;
        
        // 如果订阅已过期，则不能升级
        require(remainingTime > 0, "Subscription expired");
        
        // 计算剩余时间的月数（简化：1个月=30天）
        uint256 remainingMonths = remainingTime / (30 days);
        if (remainingTime % (30 days) > 0) {
            remainingMonths += 1; // 向上取整
        }
        
        // 计算价格差额
        uint256 priceDifference = (subscriptionPrices[newLevel] - subscriptionPrices[oldLevel]) * remainingMonths;
        require(msg.value >= priceDifference, "Insufficient payment");
        
        // 更新订阅级别
        subscriptions[msg.sender].level = newLevel;
        
        // 退还多余的ETH
        uint256 excess = msg.value - priceDifference;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
        
        emit SubscriptionUpgraded(msg.sender, oldLevel, newLevel);
    }
    
    /**
     * @dev 暂停订阅
     */
    function pauseSubscription() external {
        require(subscriptions[msg.sender].isActive, "No active subscription");
        require(!subscriptions[msg.sender].isPaused, "Subscription already paused");
        
        subscriptions[msg.sender].isPaused = true;
        pausedUsers[msg.sender] = true;
        
        emit SubscriptionPaused(msg.sender);
    }
    
    /**
     * @dev 恢复订阅
     */
    function resumeSubscription() external {
        require(subscriptions[msg.sender].isActive, "No active subscription");
        require(subscriptions[msg.sender].isPaused, "Subscription not paused");
        
        subscriptions[msg.sender].isPaused = false;
        pausedUsers[msg.sender] = false;
        
        emit SubscriptionResumed(msg.sender);
    }
    
    /**
     * @dev 检查订阅状态
     * @param user 用户地址
     * @return level 订阅级别
     * @return isActive 是否有效
     * @return isPaused 是否暂停
     * @return expiryDate 到期日期
     */
    function checkSubscription(address user) external view returns (
        SubscriptionLevel level,
        bool isActive,
        bool isPaused,
        uint256 expiryDate
    ) {
        Subscription memory sub = subscriptions[user];
        
        // 如果已过期，则视为无效
        if (sub.expiryDate < block.timestamp) {
            return (SubscriptionLevel.None, false, false, 0);
        }
        
        return (sub.level, sub.isActive, sub.isPaused, sub.expiryDate);
    }
    
    /**
     * @dev 获取所有订阅者数量
     * @return 订阅者数量
     */
    function getSubscriberCount() external view returns (uint256) {
        return subscribers.length;
    }
    
    /**
     * @dev 获取订阅价格
     * @param level 订阅级别
     * @return 价格（wei）
     */
    function getSubscriptionPrice(SubscriptionLevel level) external view returns (uint256) {
        return subscriptionPrices[level];
    }
}

/**
 * @title SubscriptionLogicV2
 * @dev 第二版逻辑合约，添加了新功能
 */
contract SubscriptionLogicV2 is SubscriptionStorage {
    /**
     * @dev 创建新订阅
     * @param level 订阅级别
     * @param durationMonths 订阅时长（月）
     */
    function subscribe(SubscriptionLevel level, uint256 durationMonths) external payable {
        require(level != SubscriptionLevel.None, "Invalid subscription level");
        require(durationMonths > 0, "Duration must be greater than 0");
        require(!subscriptions[msg.sender].isActive, "Subscription already exists");
        
        uint256 price = subscriptionPrices[level] * durationMonths;
        require(msg.value >= price, "Insufficient payment");
        
        // 计算到期日期（简化：1个月=30天）
        uint256 expiryDate = block.timestamp + (durationMonths * 30 days);
        
        // 创建订阅
        subscriptions[msg.sender] = Subscription({
            level: level,
            startDate: block.timestamp,
            expiryDate: expiryDate,
            isPaused: false,
            isActive: true
        });
        
        // 添加到订阅者列表
        subscribers.push(msg.sender);
        
        // 退还多余的ETH
        uint256 excess = msg.value - price;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
        
        emit SubscriptionCreated(msg.sender, level, expiryDate);
    }
    
    /**
     * @dev 续订订阅
     * @param durationMonths 续订时长（月）
     */
    function renewSubscription(uint256 durationMonths) external payable {
        require(subscriptions[msg.sender].isActive, "No active subscription");
        require(durationMonths > 0, "Duration must be greater than 0");
        
        SubscriptionLevel level = subscriptions[msg.sender].level;
        uint256 price = subscriptionPrices[level] * durationMonths;
        require(msg.value >= price, "Insufficient payment");
        
        // 计算新的到期日期
        uint256 newExpiryDate = subscriptions[msg.sender].expiryDate;
        if (newExpiryDate < block.timestamp) {
            newExpiryDate = block.timestamp;
        }
        newExpiryDate += (durationMonths * 30 days);
        
        // 更新订阅
        subscriptions[msg.sender].expiryDate = newExpiryDate;
        
        // 退还多余的ETH
        uint256 excess = msg.value - price;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
        
        emit SubscriptionRenewed(msg.sender, level, newExpiryDate);
    }
    
    /**
     * @dev 升级订阅级别
     * @param newLevel 新的订阅级别
     */
    function upgradeSubscription(SubscriptionLevel newLevel) external payable {
        require(subscriptions[msg.sender].isActive, "No active subscription");
        require(newLevel > subscriptions[msg.sender].level, "Can only upgrade to higher level");
        
        SubscriptionLevel oldLevel = subscriptions[msg.sender].level;
        uint256 remainingTime = subscriptions[msg.sender].expiryDate - block.timestamp;
        
        // 如果订阅已过期，则不能升级
        require(remainingTime > 0, "Subscription expired");
        
        // 计算剩余时间的月数（简化：1个月=30天）
        uint256 remainingMonths = remainingTime / (30 days);
        if (remainingTime % (30 days) > 0) {
            remainingMonths += 1; // 向上取整
        }
        
        // 计算价格差额
        uint256 priceDifference = (subscriptionPrices[newLevel] - subscriptionPrices[oldLevel]) * remainingMonths;
        require(msg.value >= priceDifference, "Insufficient payment");
        
        // 更新订阅级别
        subscriptions[msg.sender].level = newLevel;
        
        // 退还多余的ETH
        uint256 excess = msg.value - priceDifference;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
        
        emit SubscriptionUpgraded(msg.sender, oldLevel, newLevel);
    }
    
    /**
     * @dev 暂停订阅
     */
    function pauseSubscription() external {
        require(subscriptions[msg.sender].isActive, "No active subscription");
        require(!subscriptions[msg.sender].isPaused, "Subscription already paused");
        
        subscriptions[msg.sender].isPaused = true;
        pausedUsers[msg.sender] = true;
        
        emit SubscriptionPaused(msg.sender);
    }
    
    /**
     * @dev 恢复订阅
     */
    function resumeSubscription() external {
        require(subscriptions[msg.sender].isActive, "No active subscription");
        require(subscriptions[msg.sender].isPaused, "Subscription not paused");
        
        subscriptions[msg.sender].isPaused = false;
        pausedUsers[msg.sender] = false;
        
        emit SubscriptionResumed(msg.sender);
    }
    
    /**
     * @dev 检查订阅状态
     * @param user 用户地址
     * @return level 订阅级别
     * @return isActive 是否有效
     * @return isPaused 是否暂停
     * @return expiryDate 到期日期
     */
    function checkSubscription(address user) external view returns (
        SubscriptionLevel level,
        bool isActive,
        bool isPaused,
        uint256 expiryDate
    ) {
        Subscription memory sub = subscriptions[user];
        
        // 如果已过期，则视为无效
        if (sub.expiryDate < block.timestamp) {
            return (SubscriptionLevel.None, false, false, 0);
        }
        
        return (sub.level, sub.isActive, sub.isPaused, sub.expiryDate);
    }
    
    /**
     * @dev 获取所有订阅者数量
     * @return 订阅者数量
     */
    function getSubscriberCount() external view returns (uint256) {
        return subscribers.length;
    }
    
    /**
     * @dev 获取订阅价格
     * @param level 订阅级别
     * @return 价格（wei）
     */
    function getSubscriptionPrice(SubscriptionLevel level) external view returns (uint256) {
        return subscriptionPrices[level];
    }
    
    // ===== V2新增功能 =====
    
    /**
     * @dev 批量检查订阅状态
     * @param users 用户地址数组
     * @return levels 订阅级别数组
     * @return actives 是否有效数组
     * @return paused 是否暂停数组
     * @return expiryDates 到期日期数组
     */
    function batchCheckSubscriptions(address[] calldata users) external view returns (
        SubscriptionLevel[] memory levels,
        bool[] memory actives,
        bool[] memory paused,
        uint256[] memory expiryDates
    ) {
        uint256 length = users.length;
        levels = new SubscriptionLevel[](length);
        actives = new bool[](length);
        paused = new bool[](length);
        expiryDates = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
            Subscription memory sub = subscriptions[users[i]];
            
            if (sub.expiryDate < block.timestamp) {
                levels[i] = SubscriptionLevel.None;
                actives[i] = false;
                paused[i] = false;
                expiryDates[i] = 0;
            } else {
                levels[i] = sub.level;
                actives[i] = sub.isActive;
                paused[i] = sub.isPaused;
                expiryDates[i] = sub.expiryDate;
            }
        }
        
        return (levels, actives, paused, expiryDates);
    }
    
    /**
     * @dev 取消订阅并获得部分退款
     * @notice 退款金额为剩余时间的50%
     */
    function cancelSubscription() external {
        require(subscriptions[msg.sender].isActive, "No active subscription");
        
        uint256 remainingTime = subscriptions[msg.sender].expiryDate - block.timestamp;
        
        // 如果订阅已过期，则不能取消
        require(remainingTime > 0, "Subscription expired");
        
        // 计算剩余时间的月数（简化：1个月=30天）
        uint256 remainingMonths = remainingTime / (30 days);
        if (remainingTime % (30 days) > 0) {
            remainingMonths += 1; // 向上取整
        }
        
        // 计算退款金额（50%的剩余价值）
        SubscriptionLevel level = subscriptions[msg.sender].level;
        uint256 refundAmount = (subscriptionPrices[level] * remainingMonths) / 2;
        
        // 更新订阅状态
        subscriptions[msg.sender].isActive = false;
        subscriptions[msg.sender].expiryDate = block.timestamp;
        
        // 发送退款
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
        }
    }
    
    /**
     * @dev 更新订阅价格（仅限所有者）
     * @param level 订阅级别
     * @param newPrice 新价格
     */
    function updateSubscriptionPrice(SubscriptionLevel level, uint256 newPrice) external {
        require(msg.sender == owner, "Only owner can update prices");
        require(level != SubscriptionLevel.None, "Cannot set price for None level");
        
        subscriptionPrices[level] = newPrice;
    }
    
    /**
     * @dev 获取所有订阅者
     * @return 订阅者地址数组
     */
    function getAllSubscribers() external view returns (address[] memory) {
        return subscribers;
    }
    
    /**
     * @dev 获取当前版本号
     * @return 版本号
     */
    function getVersion() external pure returns (string memory) {
        return "2.0.0";
    }
}

/**
 * @title UpgradeHub
 * @dev 主合约，用于部署代理和逻辑合约
 */
contract UpgradeHub {
    SubscriptionProxy public proxy;
    SubscriptionLogic public logicV1;
    SubscriptionLogicV2 public logicV2;
    
    constructor() {
        // 部署逻辑合约V1
        logicV1 = new SubscriptionLogic();
        
        // 部署代理合约，指向逻辑合约V1
        proxy = new SubscriptionProxy(address(logicV1));
    }
    
    /**
     * @dev 升级到V2版本
     */
    function upgradeToV2() external {
        // 部署逻辑合约V2
        logicV2 = new SubscriptionLogicV2();
        
        // 升级代理合约指向V2
        proxy.upgradeLogicContract(address(logicV2));
    }
    
    /**
     * @dev 获取代理合约地址
     * @return 代理合约地址
     */
    function getProxyAddress() external view returns (address) {
        return address(proxy);
    }
    
    /**
     * @dev 获取当前逻辑合约地址
     * @return 逻辑合约地址
     */
    function getCurrentLogicAddress() external view returns (address) {
        return proxy.logicContract();
    }
}
 