// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title DecentralizedLottery
 * @dev 去中心化彩票
 * 功能点：
 * 1. 数字池每位数字从 ​​0 到 9
 * 2. 玩家选号：玩家可以在当期开奖前选择一个3位不重复的随机数字组合 需要支付0.1eth每次；单个地址仅允许选号10次每天，超过限制
 * 3. 开奖：使用 Chainlink VRF 生成随机数即彩票中奖号码 3位的随机数 限制仅所有者可操作
 * 4. 中奖：当玩家数字和顺序完全匹配中奖号码时中奖，奖金为50eth,会转账生效
 * 5. 自动：每天定时下午五点开奖,支持查询已经开奖的总期数，支持按历史期数序号查询中奖号码
 */
contract DecentralizedLottery is VRFConsumerBaseV2, AutomationCompatibleInterface, Ownable, ReentrancyGuard {
    // Chainlink VRF配置
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // 彩票配置
    uint256 public constant TICKET_PRICE = 0.1 ether;
    uint256 public constant PRIZE_AMOUNT = 50 ether;
    uint256 public constant MAX_TICKETS_PER_DAY = 10;
    uint256 public constant DRAW_INTERVAL = 1 days;
    uint256 public constant DRAW_HOUR = 17; // 17:00 (下午5点)

    // 彩票状态
    struct LotteryRound {
        uint256 roundId;
        uint256 drawTime;
        uint256[3] winningNumbers;
        bool drawn;
    }

    struct Ticket {
        address player;
        uint256[3] numbers;
        uint256 purchaseTime;
    }

    // 状态变量
    LotteryRound public currentRound;
    mapping(uint256 => LotteryRound) public lotteryHistory;
    mapping(uint256 => Ticket[]) public roundTickets;
    mapping(address => uint256) public dailyTicketCount;
    mapping(address => uint256) public lastPurchaseDay;
    
    // 事件
    event TicketPurchased(address indexed player, uint256[3] numbers, uint256 roundId);
    event WinningNumbersDrawn(uint256 indexed roundId, uint256[3] winningNumbers);
    event PrizeClaimed(address indexed winner, uint256 amount, uint256 roundId);

    constructor(
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) Ownable(msg.sender) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        // 初始化第一轮
        _initializeNewRound();
    }

    /**
     * @dev 初始化新一轮彩票
     */
    function _initializeNewRound() private {
        uint256 nextDrawTime = _getNextDrawTime();
        currentRound = LotteryRound({
            roundId: currentRound.roundId + 1,
            drawTime: nextDrawTime,
            winningNumbers: [type(uint256).max, type(uint256).max, type(uint256).max],
            drawn: false
        });
    }

    /**
     * @dev 计算下一次开奖时间
     */
    function _getNextDrawTime() private view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 currentDay = currentTime / 1 days * 1 days;
        uint256 drawTimeToday = currentDay + DRAW_HOUR * 1 hours;
        
        // 如果今天的开奖时间已过，则返回明天的开奖时间
        if (currentTime >= drawTimeToday) {
            return drawTimeToday + 1 days;
        }
        return drawTimeToday;
    }

    /**
     * @dev 购买彩票
     * @param numbers 选择的3个数字
     */
    function buyTicket(uint256[3] calldata numbers) external payable nonReentrant {
        // 检查支付金额
        require(msg.value == TICKET_PRICE, "Incorrect ticket price");
        
        // 检查开奖时间
        require(block.timestamp < currentRound.drawTime, "Round is closed for purchases");
        
        // 检查数字是否有效
        _validateNumbers(numbers);
        
        // 检查每日购买限制
        uint256 currentDay = block.timestamp / 1 days;
        if (currentDay != lastPurchaseDay[msg.sender]) {
            dailyTicketCount[msg.sender] = 0;
            lastPurchaseDay[msg.sender] = currentDay;
        }
        require(dailyTicketCount[msg.sender] < MAX_TICKETS_PER_DAY, "Daily ticket limit exceeded");
        
        // 记录购票信息
        roundTickets[currentRound.roundId].push(Ticket({
            player: msg.sender,
            numbers: numbers,
            purchaseTime: block.timestamp
        }));
        
        // 更新每日购票计数
        dailyTicketCount[msg.sender]++;
        
        emit TicketPurchased(msg.sender, numbers, currentRound.roundId);
    }

    /**
     * @dev 验证选择的数字是否有效
     * @param numbers 选择的3个数字
     */
    function _validateNumbers(uint256[3] calldata numbers) private pure {
        // 检查数字范围
        for (uint256 i = 0; i < 3; i++) {
            require(numbers[i] <= 9, "Numbers must be between 0 and 9");
        }
        
        // 检查数字是否重复
        require(numbers[0] != numbers[1] && numbers[1] != numbers[2] && numbers[0] != numbers[2], 
                "Numbers must be unique");
    }

    /**
     * @dev 获取当前轮次的所有票
     */
    function getCurrentRoundTickets() external view returns (Ticket[] memory) {
        return roundTickets[currentRound.roundId];
    }

    /**
     * @dev 获取指定轮次的中奖号码
     */
    function getWinningNumbers(uint256 roundId) external view returns (uint256[3] memory) {
        require(roundId <= currentRound.roundId, "Invalid round ID");
        require(lotteryHistory[roundId].drawn, "Round not drawn yet");
        return lotteryHistory[roundId].winningNumbers;
    }

    /**
     * @dev 获取当前轮次信息
     */
    function getCurrentRound() external view returns (
        uint256 roundId,
        uint256 drawTime,
        bool drawn,
        uint256 ticketCount
    ) {
        return (
            currentRound.roundId,
            currentRound.drawTime,
            currentRound.drawn,
            roundTickets[currentRound.roundId].length
        );
    }

    /**
     * @dev Chainlink VRF回调函数
     */
    function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords) internal override {
        uint256 randomNumber = randomWords[0];
        
        // 生成3个不重复的随机数字 (0-9)
        uint256[3] memory winningNumbers;
        uint256 availableNumbers = 10;
        uint256[10] memory numbers;
        
        // 初始化数字池
        for (uint256 i = 0; i < 10; i++) {
            numbers[i] = i;
        }
        
        // Fisher-Yates洗牌算法选择3个数字
        for (uint256 i = 0; i < 3; i++) {
            uint256 j = randomNumber % availableNumbers;
            winningNumbers[i] = numbers[j];
            numbers[j] = numbers[availableNumbers - 1];
            availableNumbers--;
            randomNumber = uint256(keccak256(abi.encode(randomNumber)));
        }
        
        // 更新当前轮次信息
        currentRound.winningNumbers = winningNumbers;
        currentRound.drawn = true;
        
        // 保存到历史记录
        lotteryHistory[currentRound.roundId] = currentRound;
        
        // 处理中奖
        _processWinners();
        
        // 初始化新一轮
        _initializeNewRound();
        
        emit WinningNumbersDrawn(currentRound.roundId - 1, winningNumbers);
    }

    /**
     * @dev 处理中奖者
     */
    function _processWinners() private {
        uint256 roundId = currentRound.roundId;
        Ticket[] storage tickets = roundTickets[roundId];
        uint256[3] memory winningNumbers = currentRound.winningNumbers;
        
        for (uint256 i = 0; i < tickets.length; i++) {
            if (_isWinningTicket(tickets[i].numbers, winningNumbers)) {
                // 发送奖金
                (bool success, ) = tickets[i].player.call{value: PRIZE_AMOUNT}("");
                require(success, "Failed to send prize");
                emit PrizeClaimed(tickets[i].player, PRIZE_AMOUNT, roundId);
            }
        }
    }

    /**
     * @dev 检查是否中奖
     */
    function _isWinningTicket(uint256[3] memory ticketNumbers, uint256[3] memory winningNumbers) 
        private pure returns (bool) 
    {
        for (uint256 i = 0; i < 3; i++) {
            if (ticketNumbers[i] != winningNumbers[i]) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Chainlink Automation检查函数
     */
    function checkUpkeep(bytes calldata /* checkData */) 
        external view override 
        returns (bool upkeepNeeded, bytes memory performData) 
    {
        bool timeReached = block.timestamp >= currentRound.drawTime;
        bool notDrawn = !currentRound.drawn;
        upkeepNeeded = timeReached && notDrawn;
        performData = ""; // 显式返回空字节数组
        return (upkeepNeeded, performData);
    }

    /**
     * @dev Chainlink Automation执行函数
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        require(block.timestamp >= currentRound.drawTime, "Draw time not reached");
        require(!currentRound.drawn, "Round already drawn");
        
        // 请求随机数
        i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    /**
     * @dev 提取合约余额（仅所有者）
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to withdraw fees");
    }

    /**
     * @dev 接收ETH
     */
    receive() external payable {}
}