
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
//导入VRFConsumerBaseV2Plus.sol fulfillRandomWords 的特殊函数
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
//VRFV2PlusClient —— 这是一个辅助库，我们想要多少个随机数，回调使用多少 gas使用哪个 Chainlink 任务（通过 keyHash）
contract FairChainLottery is VRFConsumerBaseV2Plus {
    //FairChainLottery继承VRFConsumerBaseV2Plus
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING }//枚举，彩票状态有3种，open正在进行 close关闭，calculating正在计算
    LOTTERY_STATE public lotteryState;//定义了类型为LOTTERY_STATE 公开 的状态变量 lotteryState

    address payable[] public players;//储存每轮加入的player（已经付款的）
    address public recentWinner;//记住上一轮谁赢了
    uint256 public entryFee;//设置们康费用

    // Chainlink VRF 配置
    uint256 public subscriptionId;//Chainlink 账户 ID —— 它与你的 Chainlink 订阅绑定，
    bytes32 public keyHash;//运行哪个语言机，keyHash
    uint32 public callbackGasLimit = 100000;//结果回调你的合约时设置了一个 gas 预算。
    uint16 public requestConfirmations = 3;//这设置了 Chainlink 在生成随机数之前等待多少个区块确认
    uint32 public numWords = 1;//想要一个随机数
    uint256 public latestRequestId;//请求 ID

    constructor(
        address vrfCoordinator,//这是你要部署到的区块链上 Chainlink VRF 协调器的地址。它充当接收随机性请求并返回结果的中间人。
        uint256 _subscriptionId,// 这是你的 Chainlink 订阅 ID（用于支付 VRF 请求）
        bytes32 _keyHash,//这定义了 Chainlink 应该使用哪个随机性任务。
        uint256 _entryFee// 这设置了玩家必须支付多少 ETH 才能参与每轮彩票
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {//保存部署期间传递给我们的 Chainlink 配置
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        entryFee = _entryFee;
        lotteryState = LOTTERY_STATE.CLOSED;//默认设置close
    }

    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");//只允许open时候进入
        require(msg.value >= entryFee, "Not enough ETH");//付款大于基础费用
        players.push(payable(msg.sender));//把玩家放到列表中
    }

    function startLottery() external onlyOwner {//开始游戏只有owner可以启动
        require(lotteryState == LOTTERY_STATE.CLOSED, "Can't start yet");//之前需要保证游戏关闭
        lotteryState = LOTTERY_STATE.OPEN;//将状态设置为打开
    }

    function endLottery() external onlyOwner {//结束游戏，只有owner可以启动
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        //需要状态说open的
        lotteryState = LOTTERY_STATE.CALCULATING;
        //状态先设置为计算中

        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            //我们正在制作一个要发送给 Chainlink 的随机性请求
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

        uint256 winnerIndex = randomWords[0] % players.length;//随机数除以玩家数取余数
        address payable winner = players[winnerIndex];//列表中第余数个玩家获胜
        recentWinner = winner;//储存玩家地址

        players = new address payable[](0);//清空玩家地址为下一轮做准备 (0)指的时长度为0
        lotteryState = LOTTERY_STATE.CLOSED;//游戏状态关闭
       

        (bool sent, ) = winner.call{value: address(this).balance}("");//由合约给winner转账
        require(sent, "Failed to send ETH to winner");
    }

    function getPlayers() external view returns (address payable[] memory) {
        return players;//返回当前玩家地址
    }
}

