// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract DecentralizedLottery is VRFConsumerBaseV2 {
    enum LotteryState {
        OPEN, 
        CLOSED, 
        CALCULATING 
    }
    
    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    uint64 private immutable subscriptionId;
    bytes32 private immutable keyHash;
    uint32 private constant callbackGasLimit = 100000;
    uint16 private constant requestConfirmations = 3;
    uint32 private constant numWords = 1;
    
    address public owner;
    LotteryState public lotteryState;
    uint256 public ticketPrice = 0.01 ether;
    uint256 public lastWinnerAmount;
    uint256 public lotteryId;
    
    address[] public participants;
    mapping(address => uint256) public participantTickets;
    mapping(uint256 => address) public lotteryWinners;
    mapping(uint256 => uint256) public vrfRequests; // requestId -> lotteryId
    
    event LotteryOpened(uint256 indexed lotteryId);
    event LotteryClosed(uint256 indexed lotteryId);
    event TicketPurchased(address indexed participant, uint256 tickets);
    event WinnerSelected(uint256 indexed lotteryId, address winner, uint256 amount);
    event RandomnessRequested(uint256 requestId);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    constructor(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        owner = msg.sender;
        
        lotteryState = LotteryState.CLOSED;
        lotteryId = 1;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyOpenLottery() {
        require(lotteryState == LotteryState.OPEN, "Lottery is not open");
        _;
    }
    
    function openLottery() external onlyOwner {
        require(lotteryState == LotteryState.CLOSED, "Lottery must be closed");
        
    
        delete participants;
        
        lotteryState = LotteryState.OPEN;
        emit LotteryOpened(lotteryId);
    }
    
    function buyTickets() external payable onlyOpenLottery {
        require(msg.value >= ticketPrice, "Insufficient funds for one ticket");
        
        uint256 ticketsToBuy = msg.value / ticketPrice;
        uint256 totalCost = ticketsToBuy * ticketPrice;
        
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        
        if (participantTickets[msg.sender] == 0) {
            participants.push(msg.sender);
        }
        
        participantTickets[msg.sender] += ticketsToBuy;
        emit TicketPurchased(msg.sender, ticketsToBuy);
    }
    
    function closeLotteryAndSelectWinner() external onlyOwner onlyOpenLottery {
        require(participants.length > 0, "No participants");
        
        lotteryState = LotteryState.CALCULATING;
        emit LotteryClosed(lotteryId);
        
        uint256 requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        
        vrfRequests[requestId] = lotteryId;
        emit RandomnessRequested(requestId);
    }
    
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 currentLotteryId = vrfRequests[requestId];
        require(lotteryState == LotteryState.CALCULATING, "Lottery not in calculating state");
        
        uint256 totalTickets = 0;
        for (uint256 i = 0; i < participants.length; i++) {
            totalTickets += participantTickets[participants[i]];
        }

        uint256 winnerIndex = 0;
        uint256 randomNumber = randomWords[0] % totalTickets;
        uint256 cumulativeTickets = 0;
        
        for (uint256 i = 0; i < participants.length; i++) {
            cumulativeTickets += participantTickets[participants[i]];
            if (randomNumber < cumulativeTickets) {
                winnerIndex = i;
                break;
            }
        }
        
        address winner = participants[winnerIndex];
        uint256 prizeAmount = address(this).balance;
        
        lotteryState = LotteryState.CLOSED;
        
        lotteryWinners[currentLotteryId] = winner;
        lastWinnerAmount = prizeAmount;
        
        payable(winner).transfer(prizeAmount);
        
        emit WinnerSelected(currentLotteryId, winner, prizeAmount);
        
        lotteryId++;
        
        for (uint256 i = 0; i < participants.length; i++) {
            delete participantTickets[participants[i]];
        }
        delete participants;
    }
    

    function getParticipantsCount() public view returns (uint256) {
        return participants.length;
    }
    
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function withdrawFunds() external onlyOwner {
        require(lotteryState == LotteryState.CLOSED, "Lottery must be closed");
        uint256 amount = address(this).balance;
        payable(owner).transfer(amount);
        emit FundsWithdrawn(owner, amount);
    }
    
    function setTicketPrice(uint256 newPrice) external onlyOwner {
        require(lotteryState == LotteryState.CLOSED, "Lottery must be closed");
        ticketPrice = newPrice;
    }
}
