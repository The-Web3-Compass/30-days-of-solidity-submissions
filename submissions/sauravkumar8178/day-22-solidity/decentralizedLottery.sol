// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
Lottery.sol
- Users enter by sending entranceFee
- Owner can start/stop lottery
- Owner requests randomness (Chainlink VRF v2 subscription)
- fulfillRandomWords picks a winner and sends contract balance to winner
*/

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is VRFConsumerBaseV2, Ownable {
    enum LotteryState { CLOSED, OPEN, CALCULATING }

    uint256 public entranceFee;
    address payable[] public players;
    LotteryState public lotteryState;
    uint64 public subscriptionId;
    VRFCoordinatorV2Interface public COORDINATOR;
    bytes32 public keyHash; // gasLane / key hash
    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;
    uint32 public numWords;

    // recent winner
    address public recentWinner;
    uint256 public lastRequestId;

    mapping(uint256 => address) private requestIdToCaller;

    event LotteryEntered(address indexed player);
    event LotteryStarted();
    event LotteryEnded(uint256 requestId);
    event WinnerPicked(address indexed winner, uint256 amount);

    constructor(
        uint256 _entranceFee,
        address vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) VRFConsumerBaseV2(vrfCoordinator) {
        entranceFee = _entranceFee;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = 1;
        lotteryState = LotteryState.CLOSED;
    }

    modifier onlyWhenOpen() {
        require(lotteryState == LotteryState.OPEN, "Lottery not open");
        _;
    }

    function startLottery() external onlyOwner {
        require(lotteryState == LotteryState.CLOSED, "Already started");
        delete players;
        lotteryState = LotteryState.OPEN;
        emit LotteryStarted();
    }

    function enterLottery() external payable onlyWhenOpen {
        require(msg.value >= entranceFee, "Insufficient ETH to enter");
        players.push(payable(msg.sender));
        emit LotteryEntered(msg.sender);
    }

    function endLotteryAndRequestRandomness() external onlyOwner onlyWhenOpen {
        require(players.length > 0, "No players");
        lotteryState = LotteryState.CALCULATING;
        // request random words
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        lastRequestId = requestId;
        emit LotteryEnded(requestId);
    }

    // Chainlink callback
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(lotteryState == LotteryState.CALCULATING, "Not calculating");
        uint256 randomValue = randomWords[0];
        uint256 winnerIndex = randomValue % players.length;
        address payable winner = players[winnerIndex];
        uint256 balance = address(this).balance;
        recentWinner = winner;
        lotteryState = LotteryState.CLOSED;
        // transfer prize (use call to be safe)
        (bool sent, ) = winner.call{value: balance}("");
        require(sent, "Transfer failed");
        emit WinnerPicked(winner, balance);
    }

    // convenience getters
    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }

    function getPlayersCount() external view returns (uint256) {
        return players.length;
    }

    receive() external payable {
        enterLottery();
    }
}
