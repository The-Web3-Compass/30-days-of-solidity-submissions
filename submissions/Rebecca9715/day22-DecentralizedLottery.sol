  
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract FairChainLottery is VRFConsumerBaseV2Plus {
    // 枚举当前状态，只有open可以交易
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING }
    LOTTERY_STATE public lotteryState;
    // 进行抽奖的地址list
    address payable[] public players;
    // 当前获胜地址
    address public recentWinner;
    // 费用
    uint256 public entryFee;

    // Chainlink VRF config
    uint256 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;
    uint256 public latestRequestId;

// 部署，初始化合约，设定抽奖价格、Chainlink VRF 配置（keyHash, subscriptionId 等）
    constructor(
        address vrfCoordinator,
        uint256 _subscriptionId,
        bytes32 _keyHash,
        uint256 _entryFee
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        entryFee = _entryFee;
        lotteryState = LOTTERY_STATE.CLOSED;
    }
// 参加抽奖，需要当前状态为open，给的钱大于等于抽奖入场费，将玩家地址录入players
    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        require(msg.value >= entryFee, "Not enough ETH");
        players.push(payable(msg.sender));
    }
// 管理员开启新一轮抽奖，设置当前状态为open
    function startLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Can't start yet");
        lotteryState = LOTTERY_STATE.OPEN;
    }
// 抽奖结束，发起 Chainlink 随机数请求：

    function endLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        // 状态变成 CALCULATING
        lotteryState = LOTTERY_STATE.CALCULATING;
// 用 Chainlink 的配置生成一个随机请求
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
// 记录 requestId（以后对得上）
        latestRequestId = s_vrfCoordinator.requestRandomWords(req);
    }

// Chainlink 自动调用这个函数，带着“真实随机数”来找赢家：

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING, "Not ready to pick winner");
// 用 randomWords[0] % 玩家数量 计算赢家索引
        uint256 winnerIndex = randomWords[0] % players.length;
        // 找到赢家，记录在 recentWinner
        address payable winner = players[winnerIndex];
        recentWinner = winner;

        players = new address payable[](0);
        // 状态归零（players = []，状态设为 CLOSED）
        lotteryState = LOTTERY_STATE.CLOSED;
// 合约余额全部转给中奖人！
        (bool sent, ) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send ETH to winner");
    }

    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }
}

