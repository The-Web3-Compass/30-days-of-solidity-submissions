// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract DecentralizedLottery is VRFConsumerBaseV2Plus {
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING }
    LOTTERY_STATE public lotteryState;
    
    address payable[] public players;
    address public recentWinner;
    uint256 public entryFee;
    uint256 public lotteryId;
    
    uint256 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;
    uint256 public latestRequestId;

    event LotteryStarted(uint256 indexed lotteryId, uint256 entryFee);
    event PlayerEntered(uint256 indexed lotteryId, address player);
    event WinnerSelected(uint256 indexed lotteryId, address winner, uint256 prize);
    event RandomnessRequested(uint256 indexed lotteryId, uint256 requestId);

    error LotteryNotOpen();
    error InsufficientEntryFee();
    error LotteryAlreadyOpen();
    error TransferFailed();

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
        lotteryId = 1;
    }

    function enter() public payable {
        if (lotteryState != LOTTERY_STATE.OPEN) {
            revert LotteryNotOpen();
        }
        if (msg.value < entryFee) {
            revert InsufficientEntryFee();
        }

        players.push(payable(msg.sender));
        emit PlayerEntered(lotteryId, msg.sender);
    }

    function startLottery() external onlyOwner {
        if (lotteryState != LOTTERY_STATE.CLOSED) {
            revert LotteryAlreadyOpen();
        }

        lotteryState = LOTTERY_STATE.OPEN;
        emit LotteryStarted(lotteryId, entryFee);
    }

    function endLottery() external onlyOwner {
        if (lotteryState != LOTTERY_STATE.OPEN) {
            revert LotteryNotOpen();
        }
        if (players.length == 0) {
            revert("No players in lottery");
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
        emit RandomnessRequested(lotteryId, latestRequestId);
    }

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        if (lotteryState != LOTTERY_STATE.CALCULATING) {
            revert("Not ready to pick winner");
        }

        uint256 winnerIndex = randomWords[0] % players.length;
        address payable winner = players[winnerIndex];
        recentWinner = winner;

        uint256 prize = address(this).balance;
        
        players = new address payable[](0);
        lotteryState = LOTTERY_STATE.CLOSED;

        (bool sent, ) = winner.call{value: prize}("");
        if (!sent) {
            revert TransferFailed();
        }

        emit WinnerSelected(lotteryId, winner, prize);
        lotteryId++;
    }

    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }

    function getPlayerCount() external view returns (uint256) {
        return players.length;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getLotteryInfo() external view returns (
        uint256,
        LOTTERY_STATE,
        uint256,
        uint256,
        address
    ) {
        return (
            lotteryId,
            lotteryState,
            entryFee,
            players.length,
            recentWinner
        );
    }

    function updateEntryFee(uint256 _newEntryFee) external onlyOwner {
        require(_newEntryFee > 0, "Entry fee must be greater than 0");
        require(lotteryState == LOTTERY_STATE.CLOSED, "Can only update when lottery is closed");
        entryFee = _newEntryFee;
    }

    function updateCallbackGasLimit(uint32 _newGasLimit) external onlyOwner {
        require(_newGasLimit >= 100000, "Gas limit too low");
        callbackGasLimit = _newGasLimit;
    }

    function emergencyStop() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery must be open");
        
        uint256 refundAmount = address(this).balance / players.length;
        for (uint256 i = 0; i < players.length; i++) {
            (bool success, ) = players[i].call{value: refundAmount}("");
            require(success, "Refund failed");
        }
        
        players = new address payable[](0);
        lotteryState = LOTTERY_STATE.CLOSED;
    }

    receive() external payable {}
}