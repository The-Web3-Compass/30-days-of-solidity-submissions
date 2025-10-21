// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract DecentralizedLottery is VRFConsumerBaseV2Plus {
    // Chainlink VRF config
    bytes32 private immutable s_keyHash;
    uint256 private immutable s_subscriptionId;
    uint32 private constant CALLBACK_GAS_LIMIT = 1000000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    
    uint256 public immutable entryFee; // Fee to enter lottery

    address payable[] public participants; // Current players
    
    enum LotteryState { OPEN, DRAWING, CLOSED }
    LotteryState public lotteryState; // Current lottery state
    
    uint256 public lastRequestId; // Latest VRF request ID
    address public winner;        // Last winner address

    // Events
    event LotteryEntered(address indexed participant);
    event RandomWordsRequested(uint256 indexed requestId, address requester);
    event WinnerSelected(address indexed winner, uint256 prizeAmount);

    // Errors
    error LotteryNotOpen();
    error IncorrectEntryFee(uint256 expectedFee, uint256 providedFee);
    error NoParticipants();
    error RequestIdMismatch(uint256 receivedRequestId, uint256 expectedRequestId);
    error NoRandomWordsReceived(uint256 requestId);
    error LotteryNotInDrawingState();
    error PrizeTransferFailed(address winner, uint256 amount);

    // Constructor to initialize VRF and entry fee
    constructor(
        address _vrfCoordinatorV2_5,
        bytes32 _keyHash,
        uint256 _subscriptionId,
        uint256 _entryFee
    ) VRFConsumerBaseV2Plus(_vrfCoordinatorV2_5) {
        s_keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        entryFee = _entryFee;
        lotteryState = LotteryState.OPEN;
    }

    // Enter the lottery by paying exact entry fee
    function enterLottery() external payable {
        if (lotteryState != LotteryState.OPEN) revert LotteryNotOpen();
        if (msg.value != entryFee) revert IncorrectEntryFee(entryFee, msg.value);
        participants.push(payable(msg.sender));
        emit LotteryEntered(msg.sender);
    }

    // Request Chainlink VRF random number to pick winner
    function requestLotteryWinner() external onlyOwner {
        if (lotteryState != LotteryState.OPEN) revert LotteryNotOpen();
        if (participants.length < 2) revert NoParticipants();

        lotteryState = LotteryState.DRAWING;

        lastRequestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        emit RandomWordsRequested(lastRequestId, msg.sender);
    }

    // Callback from VRF Coordinator with random number
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        if (requestId != lastRequestId) revert RequestIdMismatch(requestId, lastRequestId);
        if (randomWords.length == 0) revert NoRandomWordsReceived(requestId);
        if (lotteryState != LotteryState.DRAWING) revert LotteryNotInDrawingState();

        lotteryState = LotteryState.CLOSED;

        // Pick winner using random index
        uint256 winnerIndex = randomWords[0] % participants.length;
        winner = participants[winnerIndex];

        // Transfer entire balance as prize to winner
        uint256 prizeAmount = address(this).balance;
        (bool success, ) = payable(winner).call{value: prizeAmount}("");
        if (!success) revert PrizeTransferFailed(winner, prizeAmount);

        emit WinnerSelected(winner, prizeAmount);
    }

    // View current contract balance (prize pool)
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
