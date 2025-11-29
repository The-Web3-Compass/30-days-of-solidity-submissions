// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

// 有了继承这个基类，就可以接收Chainlink VRF v2.5 随机数
// 获得必要的函数、变量、事件、回调模版。
contract FairChainLottery is VRFConsumerBaseV2Plus{
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING } //彩票正在进行，休息，正在开奖中（锁定了）

    LOTTERY_STATE public lotteryState;

    address payable [] public players;//参与彩票的玩家
    address public recentWinner;// 获奖人
    uint256 public entryFee;//彩票准入费（多的是否要给原来的玩家）

    //与chainlink交互时候需要提供的信息
    uint256 public  subscriptionId; //记账人
    bytes32 public keyHash;//占据一个存储槽slot
    // keyHash: 具体任务标识符
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;//生成随机数前等待多少个区块确认
    uint32 public numWords = 1;//需要多少个随机数？
    uint256 public latestRequestId;//发出随机性请求后 chainlink给的请求Id

    constructor(
        address vrfCoordinator,//部署到的区块链上 Chainlink VRF 协调器的地址, 充当接收随机性请求并返回结果的中间人
        uint256 _subscription,
        bytes32 _keyHash,
        uint256 _entryFee)VRFConsumerBaseV2Plus(vrfCoordinator){
            subscriptionId = _subscription;
            keyHash = _keyHash;
            entryFee = _entryFee;
            lotteryState = LOTTERY_STATE.CLOSED;
        }

    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Not open ");//彩票还没开始
        require(msg.value >= entryFee, "Insufficient entryFee");
        players.push(payable (msg.sender));
    }

    function startLottery() external onlyOwner{//Chainlink的基础合约中存在这个修饰符 所以可以不用openzeppelin
        require(lotteryState == LOTTERY_STATE.CLOSED, "can`t start yet");//如果不是已经在休息的状态，不可以开始
        lotteryState = LOTTERY_STATE.OPEN;
    }

    function endLottery()external onlyOwner{
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");//没有开始怎么结束
        lotteryState = LOTTERY_STATE.CALCULATING;//开始抽奖了
         
        // 定义了与 VRF v2.5 请求随机数有关的数据结构，辅助函数
        // 构造请求参数、解析返回值等
        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: keyHash,
            subId: subscriptionId,
            requestConfirmations : requestConfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });
        latestRequestId = s_vrfCoordinator.requestRandomWords(req);
    }
    
    //由chainlink 自动调用
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING, "Not ready to pick winner");
        uint256 winnerIndex = randomWords[0] % players.length;
        address payable winner = players[winnerIndex];
        recentWinner = winner;

        players = new address payable [](0);//清空玩家列表
        lotteryState = LOTTERY_STATE.CLOSED;

        (bool sent, ) = winner.call{value: address(this).balance}("");//把彩票奖金给中奖人
        require(sent, "Failed to send ETH to winner");

    }
    function getPlayers() external view returns(address payable [] memory){
        return players;
    }

}