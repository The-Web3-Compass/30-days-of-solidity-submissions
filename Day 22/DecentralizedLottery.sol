// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import Chainlink VRF
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract DecentralizedLottery is VRFConsumerBaseV2 {
    // Chainlink VRF variables
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit = 200000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    // Lottery variables
    address public owner;
    address[] public players;
    address public recentWinner;
    uint256 public ticketPrice = 0.01 ether;

    event LotteryEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        owner = msg.sender;
    }

    // Enter the lottery
    function enterLottery() public payable {
        require(msg.value >= ticketPrice, "Not enough ETH to join");
        players.push(msg.sender);
        emit LotteryEntered(msg.sender);
    }

    // Request random number from Chainlink VRF
    function requestRandomWinner() external onlyOwner {
        require(players.length > 0, "No players in the lottery");
        COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    // Callback called by Chainlink VRF with random number
    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % players.length;
        recentWinner = players[indexOfWinner];
        payable(recentWinner).transfer(address(this).balance);
        emit WinnerPicked(recentWinner);

        // Reset players for next round
        delete players;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // View current players
    function getPlayers() external view returns (address[] memory) {
        return players;
    }
}
