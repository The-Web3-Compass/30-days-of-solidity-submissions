// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Import Chainlink VRF
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract FairLottery is VRFConsumerBaseV2 {
    // State variables
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING_WINNER }
    LOTTERY_STATE public lotteryState;
    address[] public players;
    address public recentWinner;
    uint256 public entryFee;
    
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 s_keyHash;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    // Events
    event LotteryEntered(address indexed player);
    event RandomnessRequested(uint256 requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 _entryFee
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        entryFee = _entryFee;
        lotteryState = LOTTERY_STATE.CLOSED;
    }

    // Enter the lottery
    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        require(msg.value == entryFee, "Incorrect entry fee");
        players.push(msg.sender);
        emit LotteryEntered(msg.sender);
    }

    // Start lottery (only owner)
    function startLottery() public {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Lottery not closed");
        lotteryState = LOTTERY_STATE.OPEN;
    }

    // End lottery and request randomness
    function endLottery() public {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        require(players.length > 0, "No players");
        
        lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
        uint256 requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        emit RandomnessRequested(requestId);
    }

    // Chainlink VRF callback
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER, "Invalid state");
        
        uint256 index = randomWords[0] % players.length;
        recentWinner = players[index];
        
        // Transfer prize
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        require(success, "Transfer failed");
        
        // Reset lottery
        players = new address[](0);
        lotteryState = LOTTERY_STATE.CLOSED;
        
        emit WinnerPicked(recentWinner);
    }
}