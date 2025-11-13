// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Core VRF consumer base
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
// VRF Coordinator interface
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract FairChainLottery is VRFConsumerBaseV2Plus {
     // VRF parameters
    uint256 public randomnessRequestId;
    bytes32 public keyHash;
    uint256 public subscriptionId;
    uint32 public callbackGasLimit = 200000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    enum LotteryState {
        OPEN,       // Players can buy tickets
        CALCULATING,// Waiting for random number / winner
        CLOSED      // Lottery ended, no actions allowed
    }
    LotteryState public lotteryState;

    address payable[] public players;
    address payable public winner;
    uint256 public entryFee;

    constructor(
        address vrfCoordinator,
        bytes32 _keyHash, 
        uint256 _subscriptionId,
        uint256 _entryFee
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        entryFee = _entryFee;
        lotteryState = LotteryState.CLOSED;
    }

    function startLottery() public onlyOwner {
        require(lotteryState == LotteryState.CLOSED, "Cannot start the lottery.");
        lotteryState = LotteryState.OPEN;
    }

    function enterLottery() external payable {
        require(msg.value >= entryFee, "Insufficient payment.");
        require(lotteryState == LotteryState.OPEN, "Lottery is closed.");

        players.push(payable(msg.sender));
    }

    function endLottery() external onlyOwner {
        require(lotteryState == LotteryState.OPEN, "Lottery not open.");
        lotteryState = LotteryState.CALCULATING;

        // Build the VRF request struct
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: keyHash,
            subId: subscriptionId,
            requestConfirmations: requestConfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        // Send request to Chainlink VRF
        randomnessRequestId = s_vrfCoordinator.requestRandomWords(request);

    }

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        lotteryState = LotteryState.CLOSED;

        winner = players[randomWords[0] % players.length];

        (bool success, ) = winner.call{value: address(this).balance}("");
        require(success, "Failed to send ether to winner.");
    }

    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }
}