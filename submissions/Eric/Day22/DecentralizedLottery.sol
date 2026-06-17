// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import Chainlink VRF interface and consumer base contract
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract LotteryWithVRF is VRFConsumerBaseV2 {
    /* ----------------------------- State Variables ----------------------------- */
    address public owner;
    address[] public players;
    address public lastWinner;

    enum LotteryState {
        OPEN,
        CALCULATING
    }
    LotteryState public lotteryState;

    uint256 public entryFee;
    uint256 public lastRandomNumber;

    // Chainlink VRF config
    VRFCoordinatorV2Interface private COORDINATOR;
    uint64 private s_subscriptionId;
    bytes32 private keyHash;
    uint32 private callbackGasLimit;
    uint16 private constant requestConfirmations = 3;
    uint32 private constant numWords = 1;

    /* ----------------------------- Events ----------------------------- */
    event Entered(address indexed player);
    event RequestedRandomness(uint256 requestId);
    event WinnerPicked(address indexed winner, uint256 prize);

    /* ----------------------------- Constructor ----------------------------- */
    constructor(
        uint64 subscriptionId_,
        address vrfCoordinator_,
        bytes32 keyHash_,
        uint256 entryFeeWei_,
        uint32 callbackGasLimit_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        owner = msg.sender;
        s_subscriptionId = subscriptionId_;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
        keyHash = keyHash_;
        entryFee = entryFeeWei_;
        callbackGasLimit = callbackGasLimit_;
        lotteryState = LotteryState.OPEN;
    }

    /* ----------------------------- Modifiers ----------------------------- */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /* ----------------------------- Core Functions ----------------------------- */
    // Players enter the lottery by paying ETH
    function enter() external payable {
        require(lotteryState == LotteryState.OPEN, "Lottery not open");
        require(msg.value == entryFee, "Incorrect entry fee");
        players.push(msg.sender);
        emit Entered(msg.sender);
    }

    // Owner triggers the draw (requests randomness)
    function startDraw() external onlyOwner {
        require(lotteryState == LotteryState.OPEN, "Already calculating");
        require(players.length > 0, "No players");

        lotteryState = LotteryState.CALCULATING;

        // Call the VRF Coordinator contract to request random numbers
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        emit RequestedRandomness(requestId);
    }

    // Chainlink VRF callback function — receives random number
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        require(lotteryState == LotteryState.CALCULATING, "Not in calculating state");
        require(players.length > 0, "No players");

        lastRandomNumber = randomWords[0];

        // Pick a winner based on the random number
        uint256 winnerIndex = randomWords[0] % players.length;
        address winner = players[winnerIndex];
        lastWinner = winner;

        // Send prize to the winner
        uint256 prize = address(this).balance;
        (bool sent, ) = winner.call{value: prize}("");
        require(sent, "Transfer failed");

        // Reset state for next round
        delete players;
        lotteryState = LotteryState.OPEN;

        emit WinnerPicked(winner, prize);
    }

    /* ----------------------------- View Functions ----------------------------- */
    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    function getState() external view returns (LotteryState) {
        return lotteryState;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /* ----------------------------- Admin Functions ----------------------------- */
    // Owner can withdraw remaining funds (in case of emergency)
    function withdraw() external onlyOwner {
        uint256 bal = address(this).balance;
        (bool sent, ) = owner.call{value: bal}("");
        require(sent, "Withdraw failed");
    }

    receive() external payable {}
    fallback() external payable {} 
}
