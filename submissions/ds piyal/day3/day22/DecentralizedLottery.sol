// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FairChainLottery is VRFConsumerBaseV2Plus, ReentrancyGuard {
    enum LOTTERY_STATE {OPEN, CLOSED, CALCULATING}
    LOTTERY_STATE public lotteryState;

    address payable[] public players;
    address public recentWinner;
    uint256 public entryFee;

    uint256 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;
    uint256 public latestRequestId;

    event LotteryStarted();
    event LotteryEnded(uint256 requestId);
    event PlayerEntered(address indexed player, uint256 entryFee);
    event WinnerPicked(address indexed winner, uint256 amount);

    error LotteryNotOpen();
    error LotteryAlreadyOpen();
    error LotteryNotClosed();
    error InsufficientEntryFee();
    error NoPlayersInLottery();
    error LotteryNotCalculating();
    error TransferFailed();
    error UnexpectedRequestId();

    constructor(
        address vrfCoordinator, 
        uint256 _subscriptionId, 
        bytes32 _keyHash, 
        uint256 _entryFee
    ) VRFConsumerBaseV2Plus(vrfCoordinator) ReentrancyGuard() {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        entryFee = _entryFee;
        lotteryState = LOTTERY_STATE.CLOSED;
    }

    function enter() public payable nonReentrant {
        if (lotteryState != LOTTERY_STATE.OPEN) {
            revert LotteryNotOpen();
        }
        if (msg.value < entryFee) {
            revert InsufficientEntryFee();
        }
        
        players.push(payable(msg.sender));
        emit PlayerEntered(msg.sender, msg.value);
    }

    function startLottery() external onlyOwner {
        if (lotteryState != LOTTERY_STATE.CLOSED) {
            revert LotteryAlreadyOpen();
        }
        lotteryState = LOTTERY_STATE.OPEN;
        emit LotteryStarted();
    }

    function endLottery() external onlyOwner {
        if (lotteryState != LOTTERY_STATE.OPEN) {
            revert LotteryNotOpen();
        }
        if (players.length == 0) {
            revert NoPlayersInLottery();
        }
        
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
        emit LotteryEnded(latestRequestId);
    }

    function fulfillRandomWords(
        uint256 requestId, 
        uint256[] calldata randomWords
    ) internal override {
        if (lotteryState != LOTTERY_STATE.CALCULATING) {
            revert LotteryNotCalculating();
        }
        
        if (requestId != latestRequestId) {
            revert UnexpectedRequestId();
        }

        uint256 winnerIndex = randomWords[0] % players.length;
        address payable winner = players[winnerIndex];
        recentWinner = winner;

        uint256 prizeAmount = address(this).balance;
        
        delete players;
        lotteryState = LOTTERY_STATE.CLOSED;

        (bool sent, ) = winner.call{value: prizeAmount}("");
        if (!sent) {
            revert TransferFailed();
        }
        
        emit WinnerPicked(winner, prizeAmount);
    }

    function getPlayers() external view returns(address payable[] memory) {
        return players;
    }

    function getPlayersCount() external view returns(uint256) {
        return players.length;
    }

    function getPrizePool() external view returns(uint256) {
        return address(this).balance;
    }

    function getLotteryState() external view returns(LOTTERY_STATE) {
        return lotteryState;
    }

    receive() external payable {}
}