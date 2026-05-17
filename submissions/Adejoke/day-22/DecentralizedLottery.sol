
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

library VRFV2PlusClient {
    struct RandomWordsRequest {
        bytes32 keyHash;
        uint256 subId;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint32 numWords;
        bytes extraArgs;
    }
    struct ExtraArgsV1 { bool nativePayment; }
    function _argsToBytes(ExtraArgsV1 memory args) internal pure returns (bytes memory) {
        return abi.encode(args.nativePayment);
    }
}

interface IVRFCoordinatorV2Plus {
    function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata req) external returns (uint256 requestId);
}

abstract contract VRFConsumerBaseV2Plus {
    IVRFCoordinatorV2Plus public s_vrfCoordinator;
    constructor(address vrfCoordinator) {
        s_vrfCoordinator = IVRFCoordinatorV2Plus(vrfCoordinator);
    }
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual;
}

contract DecentralizedLottery is VRFConsumerBaseV2Plus {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING }
    LOTTERY_STATE public lotteryState;
    address payable[] public players;
    address public recentWinner;
    uint256 public entryFee;
    uint256 public subscriptionId;
    bytes32 public keyHash;

    constructor(address vrfCoordinator, uint256 _subscriptionId, bytes32 _keyHash, uint256 _entryFee) VRFConsumerBaseV2Plus(vrfCoordinator) {
        owner = msg.sender;
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        entryFee = _entryFee;
        lotteryState = LOTTERY_STATE.CLOSED; // Lottery normally starts closed
    }

    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        require(msg.value >= entryFee, "Not enough ETH");
        players.push(payable(msg.sender));
    }

    function endLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        lotteryState = LOTTERY_STATE.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: keyHash,
            subId: subscriptionId,
            requestConfirmations: 3,
            callbackGasLimit: 100000,
            numWords: 1,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}))
        });
        s_vrfCoordinator.requestRandomWords(req);
    }

    // This callback resolves from chainlink securely fulfilling true randomness
    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        uint256 winnerIndex = randomWords[0] % players.length;
        address payable winner = players[winnerIndex];
        
        // Reset state before external calls (Reentrancy Protection)
        recentWinner = winner;
        players = new address payable[](0);
        lotteryState = LOTTERY_STATE.CLOSED;
        
        (bool sent, ) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send ETH");
    }
    
    // Admin can open the next round
    function openLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Wait until closed");
        lotteryState = LOTTERY_STATE.OPEN;
    }
}
