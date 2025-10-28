// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract FairChainLottery is VRFConsumerBaseV2Plus {
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING } LOTTERY_STATE public lotteryState; //管理游戏流程

    address payable[] public players; //存储参加此轮的每个人
    address public recentWinner; //记录谁赢了最后一轮
    uint256 public entryFee; //入场费

    uint256 public subscriptionId; //chainlink账户id
    byte32 public keyHash;  //唯一的标识符
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;
    uint256 public lastestRequestId;

    constructor(address vrfCoordinator, uint256 _subscriptionId, byte32 _keyHash, uint256 _entryFee) VRFConsumerBaseV2Plus(vrfCoordinator) {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        entryFee = _entryFee;
        lotteryState = LOTTERY_STATE.CLOSED;
    }

    //允许链上用户参与抽奖
    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "lottery not open");
        require(msg.value >= entryFee, "not enough eth");
        players.push(payable(msg.sender));
    }

    //开始启动
    function startLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "cannot start yet");
        lotteryState = LOTTERY_STATE.OPEN;
    }

    //结束游戏
    function endLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.OPEN, "lottery not open");
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

        lastestRequestId = s_vrfCoordinator.requestRandomWords(req);
    }

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING, "not ready to pick winner");

        uint256 winnerIndex = randomWords[0] % players.length;
        address payable winner = players[winnerIndex];
        recentWinner = winner;

        players = new address payable;
        lotteryState = LOTTERY_STATE.CLOSED;

        (bool sent, ) = winner.call{value: address(this).balance}("");
        require(sent, "failed to send eth to winner");
    }

    function getPlayers() external view returns (address payable[] memory){
        return players;
    }

}