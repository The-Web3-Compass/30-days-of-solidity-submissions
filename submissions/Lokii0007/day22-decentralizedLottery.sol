// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

// vrfconsumerbasev2plus - to generate random number
// vrfv2pllus - lets us configure what kind of random number do we need

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract DecentralizedLottery is VRFConsumerBaseV2Plus {
   enum LOTTERY_STATES {OPEN, CALCULATING, CLOSED}
   LOTTERY_STATES public lotteryState;

   address payable[] public players;
   address public recentWinner;
   uint public entryFee;

   uint public subscriptionId;
   bytes32 public keyHash;
   uint32 public callbackGasLimit = 100000;
   uint32 public numWords = 1;
   uint16 public requestConfirmations = 3;
   uint public latestRequestId;


   constructor(address _vrfCoordinator, uint _subscriptionId, bytes32 _keyHash, uint _entryFee) VRFConsumerBaseV2Plus(_vrfCoordinator){
     subscriptionId = _subscriptionId;
     keyHash = _keyHash;
     entryFee = _entryFee;

     lotteryState = LOTTERY_STATES.CLOSED;
   }

   function entry() payable public {
    require(lotteryState == LOTTERY_STATES.OPEN, "sabar kar thoda");
    require(msg.value >= entryFee, "gareeb");
    
    //todo check if the already person exits
    players.push(payable(msg.sender));
   }

   function startLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATES.CLOSED, "its already open or calculating");
        lotteryState = LOTTERY_STATES.OPEN;
   }

   function endLottery() external {
        require(lotteryState == LOTTERY_STATES.OPEN, "its already open or calculating");
        lotteryState = LOTTERY_STATES.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            subId: subscriptionId,
            keyHash: keyHash,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            requestConfirmations: requestConfirmations,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}))
        });

        latestRequestId = s_vrfCoordinator.requestRandomWords(req);
   }

   function fulfillRandomWords(uint , uint[] calldata randomWords) internal override{
        require(lotteryState == LOTTERY_STATES.CALCULATING, "its already open or calculating");
        uint winnerIndex = randomWords[0] % players.length;
        address payable winner = players[winnerIndex];
        recentWinner = winner;
        lotteryState = LOTTERY_STATES.CLOSED;
        
        players = new address payable[](0);
        (bool success, ) = winner.call{value: address(this).balance}("");

        require(success, "transaction failed while sending eth to winner");
   }

   function getPlayers() public view returns(address payable[] memory){
    return players;
   }
}