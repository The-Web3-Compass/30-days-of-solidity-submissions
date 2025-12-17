// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//设置chainlink
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract FairChainLottery is VRFConsumerBaseV2Plus {
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING } //枚举状态列表
    LOTTERY_STATE public lotteryState;

    //玩家跟踪
    address payable[] public players;//存储本轮加入的每个人
    address public recentWinner;//上一轮的赢家
    uint256 public entryFee;

    // Chainlink VRF 配置
    uint256 public subscriptionId;
    bytes32 public keyHash;//预言机选择，对应不同的Gas Lane
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;//生成随机数之前等待多少个区块确认，确保安全
    uint32 public numWords = 1;
    uint256 public latestRequestId;

    /**
    *@dev 初始化VRF配置和彩票状态
    *@notice 构造函数执行顺序：
    *1.首先初始化父合约VRFConSumerBaseV2Plus
    *2.设置参数
    *3.最后初始化彩票状态为关闭
    */


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

    //参加抽奖，需要......，将玩家地址录入players

    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        require(msg.value >= entryFee, "Not enough ETH");
        players.push(payable(msg.sender));
    }

    //管理员开启新一轮抽奖，设置状态为open

    function startLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Can't start yet");
        lotteryState = LOTTERY_STATE.OPEN;
    }

    //抽奖结束，发起chainlink随机数请求

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

    //chainlink自动调用这个函数，找赢家

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING, "Not ready to pick winner");

        uint256 winnerIndex = randomWords[0] % players.length;
        address payable winner = players[winnerIndex];
        recentWinner = winner;

        players = new address payable[](0);
        lotteryState = LOTTERY_STATE.CLOSED;//余额转给中奖人

        (bool sent, ) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send ETH to winner");
    }

    //返回当前玩家列表

    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }
}

