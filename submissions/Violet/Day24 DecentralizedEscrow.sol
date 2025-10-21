// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecentralizedLottery
 * @dev 一个使用Chainlink VRF来公平抽取中奖者的去中心化彩票合约。
 */
contract DecentralizedLottery is VRFConsumerBaseV2, Ownable {
    // --- 事件 ---
    event LotteryEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RandomnessRequested(uint256 indexed requestId);

    // --- 状态变量 ---
    uint256 public ticketPrice;
    address[] public players;
    
    // Chainlink VRF 相关变量
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private constant CALLBACK_GAS_LIMIT = 100000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // 存储最近一次请求的随机数结果
    uint256 public s_lastRequestId;
    uint256 public s_lastRandomWord;

    /**
     * @param _vrfCoordinatorV2 Chainlink VRF协调器的地址。
     * @param _subscriptionId 您的VRF订阅ID。
     * @param _keyHash 对应Gas价格的密钥哈希。
     * @param _ticketPrice 每张彩票的价格 (以wei为单位)。
     */
    constructor(
        address _vrfCoordinatorV2,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint256 _ticketPrice
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) Ownable(msg.sender) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        i_subscriptionId = _subscriptionId;
        i_keyHash = _keyHash;
        ticketPrice = _ticketPrice;
    }

    /**
     * @dev 允许用户购买彩票进入抽奖池。
     */
    function enterLottery() public payable {
        require(msg.value >= ticketPrice, "Not enough ETH to enter");
        players.push(msg.sender);
        emit LotteryEntered(msg.sender);
    }

    /**
     * @dev 抽奖函数（仅限所有者调用），用于向Chainlink VRF请求随机数。
     */
    function pickWinner() public onlyOwner {
        require(players.length > 0, "No players in the lottery");

        // 向VRF协调器请求一个随机数
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
        s_lastRequestId = requestId;
        emit RandomnessRequested(requestId);
    }

    /**
     * @dev Chainlink VRF的回调函数。
     * 当随机数准备好后，Chainlink节点会调用这个函数将结果返回。
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_lastRequestId == _requestId, "Request ID mismatch");
        s_lastRandomWord = _randomWords[0];

        // 使用随机数计算中奖者
        uint256 indexOfWinner = s_lastRandomWord % players.length;
        address payable winner = payable(players[indexOfWinner]);

        // 将奖池中的所有ETH转给中奖者
        (bool success, ) = winner.call{value: address(this).balance}("");
        require(success, "Transfer failed");

        emit WinnerPicked(winner);

        // 重置彩票池以进行下一轮
        players = new address[](0);
    }

    // --- 视图函数 ---
    
    function getPlayer(uint256 index) public view returns (address) {
        return players[index];
    }
    
    function getNumberOfPlayers() public view returns (uint256) {
        return players.length;
    }
}
