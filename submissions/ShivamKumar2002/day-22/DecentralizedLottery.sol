// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Ignore import errors for chainlink, that will be available on remix
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title DecentralizedLottery
 * @author shivam
 * @notice This contract implements a simple lottery using Chainlink VRF for random winner selection.
 * @dev Inherits from VRFConsumerBaseV2Plus for Chainlink VRF integration and Ownable for access control.
 */
contract DecentralizedLottery is VRFConsumerBaseV2Plus {
    // --- State Variables ---
    
    /// @notice The gas lane to use, which specifies the maximum gas price to bump to.
    /// @dev The gas lane to use, which specifies the maximum gas price to bump to. For a list of available gas lanes on each network, see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 private immutable s_keyHash;
    
    /// @notice Subscription ID for Chainlink VRF.
    uint256 private immutable s_subscriptionId;
    
    /// @notice Gas limit for the callback function from Chainlink VRF.
    uint32 private constant CALLBACK_GAS_LIMIT = 1000000;
    
    /// @notice Number of block confirmations required for the VRF request.
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    
    /// @notice Number of random words requested from Chainlink VRF.
    uint32 private constant NUM_WORDS = 1;
    
    /// @notice The required amount of ether to enter the lottery.
    uint256 public immutable entryFee;

    /// @notice Array storing the addresses of the current participants in the lottery.
    address payable[] public participants;
    
    /// @notice Enum representing the current state of the lottery.
    enum LotteryState { OPEN, DRAWING, CLOSED }
    
    /// @notice The current state of the lottery.
    LotteryState public lotteryState;

    /// @notice The ID of the most recent VRF request.
    uint256 public lastRequestId;

    /// @notice The address of the most lottery winner.
    address public winner;

    // --- Events ---

    /// @notice Emitted when a participant successfully enters the lottery.
    /// @param participant The address of the participant who entered.
    event LotteryEntered(address indexed participant);

    /// @notice Emitted when a request for random words is sent to the VRF Coordinator.
    /// @param requestId The ID of the VRF request.
    /// @param requester The address that initiated the request (contract owner).
    event RandomWordsRequested(uint256 indexed requestId, address requester);

    /// @notice Emitted when a winner is selected and the prize is transferred.
    /// @param winner The address of the selected winner.
    /// @param prizeAmount The amount of ether transferred to the winner.
    event WinnerSelected(address indexed winner, uint256 prizeAmount);

    // --- Custom Errors ---

    /// @notice Reverts when an action is attempted while the lottery is not in the OPEN state.
    error LotteryNotOpen();

    /// @notice Reverts when the incorrect entry fee is provided.
    /// @param expectedFee The required entry fee.
    /// @param providedFee The fee amount provided by the user.
    error IncorrectEntryFee(uint256 expectedFee, uint256 providedFee);

    /// @notice Reverts when attempting to draw a winner with no participants.
    error NoParticipants();

    /// @notice Reverts when the received request ID does not match the expected one.
    /// @param receivedRequestId The request ID received in the callback.
    /// @param expectedRequestId The request ID stored in the contract.
    error RequestIdMismatch(uint256 receivedRequestId, uint256 expectedRequestId);

    /// @notice Reverts when the VRF callback provides no random words.
    /// @param requestId The ID of the VRF request that failed to return words.
    error NoRandomWordsReceived(uint256 requestId);

    /// @notice Reverts when the VRF callback is received but the lottery is not in the DRAWING state.
    error LotteryNotInDrawingState();

    /// @notice Reverts when the prize transfer to the winner fails.
    /// @param winner The address of the intended recipient.
    /// @param amount The amount that failed to transfer.
    error PrizeTransferFailed(address winner, uint256 amount);

    // --- Constructor ---

    /// @notice Initializes the Lottery contract.
    /// @param _vrfCoordinatorV2_5 The address of the Chainlink VRF Coordinator contract.
    /// @param _keyHash The key hash for VRF requests.
    /// @param _subscriptionId The subscription ID for VRF.
    /// @param _entryFee The required entry fee in ether.
    constructor(
        address _vrfCoordinatorV2_5,
        bytes32 _keyHash,
        uint256 _subscriptionId,
        uint256 _entryFee
    )
        VRFConsumerBaseV2Plus(_vrfCoordinatorV2_5)
    {
        s_keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        entryFee = _entryFee;
        lotteryState = LotteryState.OPEN;
    }

    // --- Functions ---

    /**
     * @notice Allows users to enter the lottery.
     * @dev Requires sending the exact entry fee amount and the lottery must be OPEN.
     */
    function enterLottery() external payable {
        if (lotteryState != LotteryState.OPEN) {
            revert LotteryNotOpen();
        }
        if (msg.value != entryFee) {
            revert IncorrectEntryFee(entryFee, msg.value);
        }

        participants.push(payable(msg.sender));
        emit LotteryEntered(msg.sender);
    }

    /**
     * @notice Requests random words from Chainlink VRF to select a winner.
     * @dev Can only be called by the contract owner and requires at least two participants.
     */
    function requestLotteryWinner() external onlyOwner {
        if (lotteryState != LotteryState.OPEN) {
            revert LotteryNotOpen();
        }

        if (participants.length < 2) {
            revert NoParticipants();
        }

        lotteryState = LotteryState.DRAWING;

        // Will revert if subscription is not set and funded.
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

    /**
     * @notice Callback function used by VRF Coordinator to fulfill the request.
     * @dev This function is called by the VRF Coordinator after random words are generated.
     * It selects a winner, transfers the contract balance (prize) to the winner, and resets the lottery.
     * @param requestId The ID of the VRF request.
     * @param randomWords The array of random results from VRF Coordinator.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        if (requestId != lastRequestId) {
            revert RequestIdMismatch(requestId, lastRequestId);
        }
        if (randomWords.length == 0) {
            revert NoRandomWordsReceived(requestId);
        }
        if (lotteryState != LotteryState.DRAWING) {
            revert LotteryNotInDrawingState();
        }

        // Close the lottery
        lotteryState = LotteryState.CLOSED;

        // Select a winner using the first random word and modulo operator
        uint256 winnerIndex = randomWords[0] % participants.length;
        winner = participants[winnerIndex];

        // Transfer the entire contract balance to the winner
        uint256 prizeAmount = address(this).balance;
        (bool success, ) = payable(winner).call{value: prizeAmount}("");
        if (!success) {
            revert PrizeTransferFailed(winner, prizeAmount);
        }

        emit WinnerSelected(winner, prizeAmount);
    }

    // --- View Functions ---

    /**
     * @notice Returns the current balance of the contract (the prize pool).
     * @return contractBalance The contract balance in ether.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
