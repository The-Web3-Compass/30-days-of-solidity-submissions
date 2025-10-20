// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract FairChainLottery is VRFConsumerBaseV2Plus {
    // 状态管理
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING }
    LOTTERY_STATE public lotteryState;

    // 记录参与者
    address payable[] public players;
    address public recentWinner;
    uint256 public entryFee;

    // Chainlink VRF config ：预言机服务通常需要付费和配置参数
    uint256 public subscriptionId; // Chainlink 订阅号，支付随机数服务费
    bytes32 public keyHash; // 指定用哪个VRF服务 不同 keyHash 代表不同配置
    uint32 public callbackGasLimit = 100000; //Chainlink 回调时能用多少 gas，太低可能失败，太高浪费钱
    uint16 public requestConfirmations = 3; // 等多少区块确认，越多越安全但越慢
    uint32 public numWords = 1; // 要几个随机数（本例只需 1 个）
    uint256 public latestRequestId; // 记录最近一次请求，便于追踪

    // 部署时要指定 Chainlink 服务地址、订阅号、keyHash、门票价格，初始化彩票为“未开放”状态
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

    // 只有在售票期间才能买票，且必须付够钱
    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        require(msg.value >= entryFee, "Not enough ETH");
        players.push(payable(msg.sender));
    }

    function startLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Can't start yet");
        lotteryState = LOTTERY_STATE.OPEN;
    }

    function endLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        lotteryState = LOTTERY_STATE.CALCULATING;
        // 构造 Chainlink 随机数请求
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
        // 把请求发送给 Chainlink VRF 协调器（Coordinator），Coordinator 会广播给预言机网络
        latestRequestId = s_vrfCoordinator.requestRandomWords(req);
    }

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING, "Not ready to pick winner");
        // randomWords[0] : Chainlink VRF 返回的安全随机数， %players.length : 保证中奖者索引在玩家数组范围内
        uint256 winnerIndex = randomWords[0] % players.length;
        address payable winner = players[winnerIndex];
        recentWinner = winner;

        players = new address payable[](0) ;
        lotteryState = LOTTERY_STATE.CLOSED;

        (bool sent, ) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send ETH to winner");
    }

    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }
}

