// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { VRFConsumerBaseV2Plus } from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import { VRFV2PlusClient } from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
// import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
// NOTE - VRFConsumerBaseV2Plus already has its own Ownable impl

/**
 * @title DecentralisedLottery
 * @dev Build a fair and random lottery!
 * You'll learn how to use external services like Chainlink VRF to generate random numbers.
 * It's like a lottery on the blockchain, demonstrating how to use external randomness.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 22
 */
contract DecentralisedLottery is VRFConsumerBaseV2Plus {
    enum LOTTERY_STATUS { OPEN, CLOSED, CALCULATING }

    uint256 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;
    uint256 public latestRequestId;
    
    LOTTERY_STATUS public lotteryStatus;
    address[] public entrants;
    address public latestWinner;
    uint256 public fee;

    constructor(address vrfCoordinator) VRFConsumerBaseV2Plus(vrfCoordinator) {
    }

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        require(lotteryStatus == LOTTERY_STATUS.CALCULATING, "cannot calculate winner now");

        uint256 winnerIndex = randomWords[0] % entrants.length;
        address payable winner = payable(entrants[winnerIndex]);
        latestWinner = winner;

        entrants = new address[](0);
        lotteryStatus = LOTTERY_STATUS.CLOSED;

        (bool transferSuccess, ) = winner.call{value: address(this).balance}("");
        require(transferSuccess, "transfer failed");
    }
    
    function startLottery() public onlyOwner {
        require(lotteryStatus == LOTTERY_STATUS.CLOSED, "cannot start lottery now");
        lotteryStatus = LOTTERY_STATUS.OPEN;
    }
    
    function endLottery() public onlyOwner {
        require(lotteryStatus == LOTTERY_STATUS.OPEN, "cannot end lottery now");
        lotteryStatus = LOTTERY_STATUS.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            subId: subscriptionId,
            keyHash: keyHash,
            requestConfirmations: requestConfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({ nativePayment: true })
            )
        });

        latestRequestId = s_vrfCoordinator.requestRandomWords(req);
    }

    function enter() public payable {
        require(lotteryStatus == LOTTERY_STATUS.OPEN, "cannot enter lottery now");
        require(msg.value >= fee, "fee too little");
        entrants.push(msg.sender);
    }

    receive() external payable {
        enter();
    }
}
