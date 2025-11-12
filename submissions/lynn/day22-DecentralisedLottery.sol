//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.4.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts@1.4.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract DecentralisedLottery is VRFConsumerBaseV2Plus {
    enum LotteryState {OPEN, CLOSED, CACULATING}
    LotteryState public state;

    address[] public players;
    address public recentWinner;
    uint256 public entryFee;

    // Chainlink VRF config
    uint256 public subscriptionId; // Chainlink account ID
    bytes32 public keyHash; // identifie the Chainlink oracle with the specific configuration of the VRF service
    uint32 public callbackGasLimit = 100000;
    uint16 public requestconfirmations = 3; //set block confirmations Chainlink waits for before generating the random number
    uint32 public numWords = 1; // set random numbers
    uint256 public latestRequestId;

    constructor(
        address _vrfCoordinator,
        uint256 _subscriptionId,
        bytes32 _keyHash,
        uint256 _entryFee
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        entryFee = _entryFee;
        state = LotteryState.CLOSED;
    }

    function startLottery() external onlyOwner {
        require(state == LotteryState.CLOSED, "Lottery is already open");
        state = LotteryState.OPEN;
    }

    function entry() external payable {
        require(state == LotteryState.OPEN, "Lottery not open");
        require(msg.value >= entryFee, "Not enough entryFee");
        players.push(msg.sender);
    }

    function endLottery() external onlyOwner {
        require(state == LotteryState.OPEN, "Lottery not oopen");
        state = LotteryState.CACULATING;

        // build a randomness request
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: keyHash,
            subId: subscriptionId,
            requestConfirmations: requestconfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
            )
        });
        // send the request to Chainlink VRF
        latestRequestId = s_vrfCoordinator.requestRandomWords(request);
    }

    // Automatically called by Chainlink when it finish the random words caculating
    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        require(state == LotteryState.CACULATING, "Not ready to pick winner");
        require(randomWords.length > 0, "No random words received");

        uint256 winnerIndex = randomWords[0] % players.length;
        recentWinner = players[winnerIndex];
        players = new address[](0);
        state = LotteryState.CLOSED;

        (bool success, ) = payable(recentWinner).call{value: address(this).balance}("");
        require(success, "Transfer to winner failed");
    }

    function getPlayers() external view returns(address[] memory) {
        return players;
    }

    function getLotteryState() external view returns(string memory) {
        if (state == LotteryState.OPEN) return "OPEN";
        else if (state == LotteryState.CLOSED) return "CLOSED";
        else return "CACULATING";
    }
}