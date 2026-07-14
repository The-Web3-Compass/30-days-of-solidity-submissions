// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FairChainLottery is VRFConsumerBaseV2Plus, Ownable {
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING }
    LOTTERY_STATE public lotteryState;

    address payable[] public players;
    address public recentWinner;
    uint256 public entryFee;

    // Chainlink VRF configuration (v2.5)
    uint256 public subscriptionId;
    bytes32 public keyHash;
    uint32  public callbackGasLimit = 100000;
    uint16  public requestConfirmations = 3;
    uint32  public numWords = 1;

    uint256 public latestRequestId;

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
    }

    function enter() external payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        require(msg.value >= entryFee, "Insufficient entry fee");
        players.push(payable(msg.sender));
    }

    function startLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Lottery already active");
        lotteryState = LOTTERY_STATE.OPEN;
    }

    function endLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        require(players.length > 0, "No players");
        lotteryState = LOTTERY_STATE.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: keyHash,
            subId: subscriptionId,
            requestConfirmations: requestConfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            // nativePayment: true or false depends on your funding method; set to true for native payments
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({ nativePayment: true })
            )
        });

        latestRequestId = s_vrfCoordinator.requestRandomWords(req);
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomWords
    ) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING, "Not calculating");

        uint256 winnerIndex = randomWords[0] % players.length;
        address payable winner = players[winnerIndex];

        recentWinner = winner;
        lotteryState = LOTTERY_STATE.CLOSED;

        // Reset players before transfer to reduce reentrancy surface
        delete players;

        (bool sent, ) = winner.call{ value: address(this).balance }("");
        require(sent, "Prize transfer failed");
    }

    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }
}