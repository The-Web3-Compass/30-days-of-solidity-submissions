// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Chainlink 提供的一个基础合约，fulfillRandomWords 要用
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
// 辅助函数，提供了一种简单的方式来构造和格式化我们发送给 Chainlink 的随机性请求
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract FairChainLottery is VRFConsumerBaseV2Plus{
    // 彩票状态:打开、关闭、计算中
    enum LOTTERY_STATE {OPEN, CLOSED, CALCULATING} 
    LOTTERY_STATE public lotteryState ;
    // 玩家信息
    address payable[] public players;
    address public recentWinner;
    uint256 public entryFee;
    // Chainlink VRF 相关
    uint256 public subscriptionId;
    bytes32 public keyHash;// Chainlink VRF密钥哈希
    uint32 public callbackGasLimit = 100000; //回调函数的gas限制（默认100000）
    uint16 public requestConfirmations = 3; //随机数请求的确认区块数（默认3）
    uint32 public numWords = 1; //请求的随机数数量（默认1）,选择一个玩家
    uint256 public latestRequestId; //最新的随机性请求ID

    constructor(
        address vrfCoordinator, //部署到的区块链上 Chainlink VRF 协调器的地址
        uint256 _subscriptionId,
        bytes32 _keyHash,
        uint256 _entryFee
    ) VRFConsumerBaseV2Plus(vrfCoordinator){
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        entryFee = _entryFee;
        lotteryState = LOTTERY_STATE.CLOSED; //默认关闭
    }
    // 进入转盘
    function enter() public payable {
        require(lotteryState==LOTTERY_STATE.OPEN, "Lottery not open");
        require(msg.value>=entryFee,"Not enough ETH");
        // 加入用户
        players.push(payable(msg.sender)); //记为 payable，以便向其转移资金。
    }
    // 开始转盘
    function startLottery() external onlyOwner{
        require(lotteryState == LOTTERY_STATE.CLOSED, "Can't start yet");
        lotteryState = LOTTERY_STATE.OPEN;
    }
    // 结束转盘
    function endLottery()external onlyOwner{
        require(lotteryState == LOTTERY_STATE.OPEN, "Can't end,Lottery not open");
        lotteryState = LOTTERY_STATE.CALCULATING; // 选择赢家

        // 构建请求
        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest(
            {
                keyHash:keyHash, //使用哪个随机性任务
                subId: subscriptionId, //谁在付款
                requestConfirmations: requestConfirmations, //等待多少确认
                callbackGasLimit: callbackGasLimit, //响应时使用多少 gas
                numWords: numWords,
                extraArgs:VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
                )
            }
        );
        // 发送请求
        latestRequestId = s_vrfCoordinator.requestRandomWords(req);

    }
    // 增加随机性
    function fulfillRandomWords(uint256,uint256[] calldata randomWords) internal override {
        require(lotteryState==LOTTERY_STATE.CALCULATING, "Not ready to pick winner");

        // 选择赢家
        uint256 winnerIndex=randomWords[0]% players.length;
        address payable winner = players[winnerIndex];

        recentWinner =winner;
        // 下一轮重置
        players=new address payable [](0);
        lotteryState = LOTTERY_STATE.CLOSED;
        // 发送奖金
        (bool sent,)=winner.call{value:address(this).balance}("");
        require(sent,"Failed to send ETH to winner");
    }
    // 获取玩家信息
    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }
}