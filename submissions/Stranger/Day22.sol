
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract FairChainLottery is VRFConsumerBaseV2Plus {
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING }  // 彩票状态定义为枚举类型, 隐式整数值从0开始
    LOTTERY_STATE public lotteryState;                // 彩票当前状态

    address payable[] public players;     // 玩家列表
    address public recentWinner;          // 最近的赢家
    uint256 public entryFee;              // 入场费

    // Chainlink VRF(Verifiable Random Function, 可验证随机函数) 配置
    uint256 public subscriptionId;           // Chainlink VRF订阅ID
    bytes32 public keyHash;                  // CHainlink VRF密钥哈希
    uint32 public callbackGasLimit = 100000; // chainlink回调fulfillRandomWords时的gas限制
    uint16 public requestConfirmations = 3;  // 随机数请求的确认区块数量
    uint32 public numWords = 1;              // 请求多少个随机数(默认1)
    uint256 public latestRequestId;          // 最新的随机性请求ID

    constructor(
        address vrfCoordinator,
        uint256 _subscriptionId,
        bytes32 _keyHash,
        uint256 _entryFee
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        subscriptionId = _subscriptionId;    // Chainlink VRF协调器的地址, 它是接收随机性请求并返回结果的中间人
        keyHash = _keyHash;
        entryFee = _entryFee;
        lotteryState = LOTTERY_STATE.CLOSED; // 只有Closed时才能开启新一轮
    }

    // 彩票售票
    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        require(msg.value >= entryFee, "Not enough ETH");
        players.push(payable(msg.sender));  // 将玩家添加至列表并标识为payable以便后续向玩家转移资金
    }

    // 切换状态开始新一轮彩票售票
    function startLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Can't start yet");
        lotteryState = LOTTERY_STATE.OPEN;
    }

    // 结束彩票售票
    function endLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        lotteryState = LOTTERY_STATE.CALCULATING;

        // 制作发给chainlink的随机性请求
        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: keyHash,
            subId: subscriptionId,
            requestConfirmations: requestConfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
            )
        });

        // 发送请求
        latestRequestId = s_vrfCoordinator.requestRandomWords(req);
    }

    // 由Chainlink 自动调用的回调函数, 它在返回随机数时自动调用此函数
    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING, "Not ready to pick winner");

        // 选择一个赢家, 序号为0 -> 玩家数-1
        uint256 winnerIndex = randomWords[0] % players.length;
        address payable winner = players[winnerIndex];
        // 更新最新的中奖人员
        recentWinner = winner;

        // 重置变量, 准备下一轮抽奖
        players = new address payable[](0);
        lotteryState = LOTTERY_STATE.CLOSED;
        // 发送奖金
        (bool sent, ) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send ETH to winner");
    }

    // 获取玩家列表
    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }
}

