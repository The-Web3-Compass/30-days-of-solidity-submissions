//Chainlink VRF — 一个在链上运行的可靠随机数来源
//合约上的内容一般都是可预测的，但这个可以生成随机数，还有一个受信任的保障

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//要用metamask还有sepolia

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
//2个import：第一个是随机数，随机数准备好时，Chainlink 会自动调用该函数
//第二个是辅助函数，看一下这次调用发生了什么

contract FairChainLottery is VRFConsumerBaseV2Plus {

    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING }
    //系统需要规则，enum=enumeration 枚举，列举

    //定义了三种模式，open人才进来，close后开新一轮，计算中时不允许进入
    LOTTERY_STATE public lotteryState;
    //管理游戏流程并在正确的时间执行正确的规则

    address payable[] public players;
    //要赢钱的
    address public recentWinner;
    uint256 public entryFee;
    //要有入场费

    //要明确到底要什么样的随机数
    uint256 public subscriptionId;
    //从xx的会员卡上扣钱
    bytes32 public keyHash;
    //指定xx来制作哈希值
    uint32 public callbackGasLimit = 100000;
    
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;
    uint256 public latestRequestId;



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

        latestRequestId = s_vrfCoordinator.requestRandomWords(req);
    }

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING, "Not ready to pick winner");

        uint256 winnerIndex = randomWords[0] % players.length;
        address payable winner = players[winnerIndex];
        recentWinner = winner;

        players = new address payable ;
        lotteryState = LOTTERY_STATE.CLOSED;

        (bool sent, ) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send ETH to winner");
    }

    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }
}

