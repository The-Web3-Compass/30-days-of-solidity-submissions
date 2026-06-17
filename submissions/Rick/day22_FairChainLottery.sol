// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract FairChainLottery is VRFConsumerBaseV2Plus{
    enum LOTTERY_STATE{OPEN,CLOSED,CALCULATING}
    LOTTERY_STATE public state;

    // 抽奖用户地址  payable声明用于发放奖品
    address payable[] public players;
    // 上一轮获胜者
    address public lastWinner;
    // 每个用户参与抽奖的ETH费用
    uint public entryFee;

    // chinaLink 配置
    // VRF创建的订阅id
    uint256 public subscriptionId;
    // VRF不同网络下的keyhash
    bytes32 public keyHash;
    // 随机数回调接口时最高gas费用
    uint32 public callbackGasLimit = 100000;
    // VRF获取随机数 等待几个区块确认数据可靠
    uint16 public requestConfirmations = 3;
    // 返回几个随机数
    uint32 public numWords = 1;
    // 最近一次请求随机数的id
    uint256 public latestRequestId;

    constructor(address vrfCoordinator, uint256 _subscriptionId,bytes32 _keyHash,uint256 _entryFee) VRFConsumerBaseV2Plus(vrfCoordinator){
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        entryFee = _entryFee;
        state = LOTTERY_STATE.CLOSED;
    }

    // 计入抽奖活动
    function join() public payable{
        require(state == LOTTERY_STATE.OPEN ,"not open");
        require(msg.value >= entryFee,"not enough fee");
        players.push(payable(msg.sender));
    }

    function startLottery()external  onlyOwner{
        require(state == LOTTERY_STATE.CLOSED,"not closed");
        state = LOTTERY_STATE.OPEN;
    } 

    //活动抽奖结算
    function endLottery() external onlyOwner{
        require(state == LOTTERY_STATE.OPEN,"not closed");
        state = LOTTERY_STATE.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: keyHash,
            subId: subscriptionId,
            requestConfirmations: requestConfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            // 给VRF传递补充参数， true使用原生ETH支付， false使用link代币支付，需要提前存入到订阅中
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
            )
        });
        // s_vrfCoordinator 是VRFConsumerBaseV2Plus初始化时 vrfCoordinator的地址，指向一个实例
        latestRequestId = s_vrfCoordinator.requestRandomWords(req);

    }

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal  override {
        require(state == LOTTERY_STATE.CALCULATING, "Not ready to pick winner");

        uint256 winnerIndex = randomWords[0] % players.length;
        address payable winner = players[winnerIndex];
        lastWinner = winner;

        players = new address payable[](0) ;
        // delete players ;
        state = LOTTERY_STATE.CLOSED;

        (bool success ,) = winner.call{value : address(this).balance}("");
        require(success , "call failed");
    }
}
