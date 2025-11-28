// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract FairChainLottery is VRFConsumerBaseV2Plus{
    enum  LOTTERY_STATUS{OPEN,CLOSED,CALCULATING}  //彩票游戏状态：进行 结束 计算胜者中
    LOTTERY_STATUS public lotteryStatus;
    
    address payable[] public players; //本轮游戏参与者
    address public recentWinner;//最近一轮胜者
    uint256 public entryFee;//参与费用

    // Chainlink VRF 配置
    uint256 public subscriptionId;  //chainlink账号
    bytes32 public keyHash;         //预言机的唯一标识
    uint32 public callbackGasLimit = 100000;      
    uint16 public requestConfirmations = 3;     //等待3个区块确认
    uint32 public numWords = 1;            //请求的随机数个数
    uint256 public latestRequestId;        //请求ID

    constructor(
        address vrfCoordinator,  //chainlink协调器地址
        uint256 _subscriptionId,
        bytes32 _keyHash,
        uint256 _entryFee
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        entryFee = _entryFee;
        lotteryStatus = LOTTERY_STATUS.CLOSED;  //设置游戏状态关闭（未开始）
    }
    //开始游戏
    function start() external onlyOwner{
        require(lotteryStatus == LOTTERY_STATUS.CLOSED,"The game is already open!");
        lotteryStatus = LOTTERY_STATUS.OPEN;
    }

     //参加游戏
    function entry() payable public{
        require(lotteryStatus == LOTTERY_STATUS.OPEN,"The game is not open!");
        require(msg.value >= entryFee,"Not enough fee!");
        players.push(payable(msg.sender));
    }

    //随机选定胜者结束游戏
    function end() external onlyOwner{
        require(lotteryStatus == LOTTERY_STATUS.OPEN,"The game is already open!");
        lotteryStatus = LOTTERY_STATUS.CALCULATING;

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
         //发送请求
        latestRequestId = s_vrfCoordinator.requestRandomWords(req);
    }

    //chainlink会自动调用这个函数
    function fulfillRandomWords(uint256,uint[] calldata randomWords) internal override{
        require(lotteryStatus == LOTTERY_STATUS.CALCULATING,"Incorrect status!");
        uint256 winnerId = randomWords[0] % players.length;  //根据随机数决定胜者
        address payable winnerAdr = players[winnerId];
        recentWinner = winnerAdr;

        players = new address payable[](0);  //重置
        lotteryStatus = LOTTERY_STATUS.CLOSED;

        (bool success,) = winnerAdr.call{value: address(this).balance}("");
        require(success,"Send failed!");

    }

    //查参与者
    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }

}